-- | A cache with bundling and throttling.
--
-- This module allows you to cache the results of loading resources and
-- it track versions of them in order to support efficient reloading.
--
-- The functions are ordered by the freshness guarantee that they provide,
-- from the best to the worst.
module ASTMap
  ( -- * Time utilities
    Timestamp
  , getTimestamp

    -- * Definition and creation
  , ASTMap
  , empty

    -- * Insertion
  , insert

    -- * Deletion
  , delete

    -- * Fetching
  , fetchLatest
  , fetchCurrent
  , fetchBundled
  , fetchCached

    -- * Fetching with background loading
  , fetchFast
  , fetchFastAndNotify

    -- * Invalidation
  , invalidate
  ) where

import Control.Concurrent.STM (STM, retry)
import Control.Monad.IO.Class (MonadIO, liftIO)
import Data.Functor ((<&>), void)
import Data.Hashable (Hashable)
import Data.Maybe (fromMaybe)
import Control.Monad (when)
import Focus (Focus)
import Focus qualified
import StmContainers.Map (Map)
import StmContainers.Map qualified as Map
import System.Clock (Clock (Monotonic), TimeSpec, getTime)
import UnliftIO (Async, MonadUnliftIO, async, atomically, cancel)

----
---- Implementation notes:
----
--
-- We associate multiple timestamps with each value that has been
-- loaded or is being loaded currently, in particular:
--
-- * For every cached value we remember when the IO action that loaded it started.
-- * When was the last time each value got invalidated.
-- * If someone is currently loading/reloading a value, when they started.
--
-- This makes it possible to tell if the value is up to date and minimise the
-- number of actual loads, e.g. when the value is outdated, but we are already
-- loading it, so we can just wait for the result.
--
-- * A value is up to date iff its timestamp is > its last invalidation time.
-- * When a value is being loaded in another thread, it might be that when
--   that load finishes, the value will already by out of date, and we
--   can tell this by comparing the load strated time with last invalidation time.
-- * Having timestamps on values means we can guarantee that even if some thread
--   is slow, it will never replace the cache with an older value.

-- | Monotonically increasing time-like value.
type Timestamp = TimeSpec

getTimestamp :: MonadIO m => m Timestamp
getTimestamp = liftIO $ getTime Monotonic

-- | The cache-map.
data ASTMap k v m = ASTMap
  { amValues :: Map k (v, Timestamp)
    -- ^ Cached values and when the actions that loaded them started.
  , amLoadStarted :: Map k Timestamp
    -- ^ Who is loading what and when they started.
  , amInvalid :: Map k Timestamp
    -- ^ When each value was invalidated last.
  , amWorkers :: Map k (Async v)
    -- ^ Background threads loading values.
  , amLoad :: k -> m v
    -- ^ Loading action.
  }

-- | Construct a new empty 'ASTMap' given the loading action.
empty :: (k -> m v) -> IO (ASTMap k v m)
empty load = atomically $
  ASTMap <$> Map.new <*> Map.new <*> Map.new <*> Map.new <*> pure load

-- | Insert some value into an 'ASTMap'.
insert
  :: ( Eq k, Hashable k
     , MonadIO m
     )
  => k  -- ^ Key
  -> v  -- ^ Value
  -> Timestamp  -- ^ Current timestamp
  -> ASTMap k v m  -- ^ Map
  -> m ()
insert k v time ASTMap{amValues} =
  void $ atomically $ Map.focus (insertOrChooseNewer snd (v, time)) k amValues

-- | Delete a value from an 'ASTMap'. Returns the deleted value, if it exists.
delete
  :: ( Eq k, Hashable k
     , MonadIO m
     )
  => k  -- ^ Key
  -> ASTMap k v m  -- ^ Map
  -> m (Maybe v)
delete k tmap@ASTMap{amValues, amLoadStarted, amInvalid} = do
  time <- getTimestamp
  go <- checkIfLoading time k tmap
  if go then
    atomically do
      Map.delete k amLoadStarted
      Map.delete k amInvalid
      v <- Map.focus Focus.lookupAndDelete k amValues
      pure $ fst <$> v
  else
    -- Someone started to load it... maybe the file was recreated after it was
    -- deleted and we didn't have enough time somehow? Do nothing I guess...
    pure Nothing

checkIfLoading
  :: ( Eq k, Hashable k
     , MonadIO m
     )
  => Timestamp -> k -> ASTMap k v m -> m Bool
checkIfLoading vNew k ASTMap{amLoadStarted} =
  atomically $ Map.focus go k amLoadStarted
  where
    go = Focus.cases (True, Focus.Leave) \vOld -> (vNew >= vOld, Focus.Leave)

-- | Load the current value.
--
-- This is an internal function, it does not check whether the cached
-- value is valid or not. However, if someone else is already loading
-- the value at a newer timestamp, it will wait for their result.
--
-- Also, it will never overwrite a cached value with an older one.
loadValue
  :: ( Eq k, Hashable k
     , MonadIO m
     )
  => k  -- ^ Key
  -> ASTMap k v m  -- ^ Map
  -> Timestamp  -- ^ Current timestamp
  -> m v
loadValue k ASTMap{amValues, amLoadStarted, amLoad} time = do
    go <- atomically $ Map.focus (insertOrChooseNewer id time) k amLoadStarted
    if go then do
      v <- amLoad k
      -- Cache the value, but only if ours is newer than the current cache
      atomically $ Map.focus (insertOrChooseNewer snd (v, time)) k amValues
      pure v
    else
      -- Someone else is loading it and they somehow managed to start later than
      -- we did, so... why not just wait for them?
      atomically $ Map.lookup k amValues >>= \case
        Just (v, _timestasmp) -> pure v
        Nothing -> retry

-- | Invalidate the cached value for the given key.
invalidate
  :: ( Eq k, Hashable k
     , MonadIO m
     )
  => k  -- ^ Key
  -> ASTMap k v m  -- ^ Map
  -> m ()
invalidate k ASTMap{amInvalid} = do
  invTime <- getTimestamp
  atomically $ void $ Map.focus (insertOrChooseNewer id invTime) k amInvalid

-- | Fetch the version of the value which is up to date at the time
-- of the call to this function.
--
-- More specifically, if there is a cached value that was not invalidated,
-- return this value. If there is no value or it was invalidated, load it,
-- unless someone else is already loading it. If someone is loading it, and they
-- started after the latest invalidation so far, then return what they will get.
-- If what they are fetching has potentially been invalidated, just fetch
-- ourselves in parallel.
fetchCurrent
  :: forall k v m
  .  ( Eq k, Hashable k
     , MonadIO m
     )
  => k -> ASTMap k v m -> m v
fetchCurrent k tmap = fst <$> fetchCurrent' k tmap

-- | Internal version of 'fetchCurrent' which returns a timestamp too.
fetchCurrent'
  :: forall k v m
  .  ( Eq k, Hashable k
     , MonadIO m
     )
  => k -> ASTMap k v m -> m (v, Timestamp)
fetchCurrent' k tmap@ASTMap{amValues, amLoadStarted, amInvalid} = do
    time <- getTimestamp
    let
      seeIfSomeoneIsFetchingIt :: STM (Maybe (v, Timestamp))
      seeIfSomeoneIsFetchingIt =
        Map.lookup k amLoadStarted >>= \case
          Nothing ->
            -- Nope, no one is fetching it
            pure Nothing
          Just startTime
            | startTime >= time ->
                -- Someone started fetching it after our current time!
                -- They???ll get a value newer than current time and it works for us.
                Map.lookup k amValues >>= \case
                  Just res -> pure $ Just res
                  Nothing -> retry
            | otherwise ->
                -- They will get some value, but it will be outdated.
                pure Nothing
    mres <- atomically $ Map.lookup k amValues >>= \case
      Nothing ->
        -- No value in the cache
        seeIfSomeoneIsFetchingIt
      Just res@(_, vTime) ->
        -- There is some value in the cache, but how good is it?
        Map.lookup k amInvalid >>= \case
          Nothing ->
            -- The value is valid, because it has never been invalidated
            pure $ Just res
          Just invTime
            | vTime > invTime ->
                -- It has been reloaded since invalidation
                pure $ Just res
            | otherwise ->
                -- It is outdated, need to reload
                seeIfSomeoneIsFetchingIt
    case mres of
      Just res -> pure res
      Nothing -> (, time) <$> loadValue k tmap time

-- | Fetch a version of the value, which is up to date at the time
-- this function /returns/.
--
-- This function will get a value form the cache or load it if needed,
-- but then it will check to see if the value is still up to date
-- and if not, do all again.
--
-- Note that this means that this function can take a long time to
-- return if the value is constantly getting invalidated, however
-- sometimes it might be better to take more time rather than provide
-- an immediately outdated result...
fetchLatest
  :: forall k v m
  .  ( Eq k, Hashable k
     , MonadIO m
     )
  => k -> ASTMap k v m -> m v
fetchLatest k tmap@ASTMap{amInvalid} = go
  where
    go = do
      (v, vTime) <- fetchCurrent' k tmap
      again <- atomically $
        Map.lookup k amInvalid <&> \case
          Nothing -> False
          Just invTime
            | vTime > invTime -> False
            | otherwise -> True
      if again then go else pure v

-- | Fetch a cached version of the value.
--
-- This function will load a value if there is no cache for it, but
-- otherwise will just return the cached one, regardless of how outdated
-- it may be.
fetchCached
  :: forall k v m
  .  ( Eq k, Hashable k
     , MonadIO m
     )
  => k -> ASTMap k v m -> m v
fetchCached k tmap@ASTMap{amValues} = do
  mv <- atomically $ Map.lookup k amValues
  case mv of
    Nothing -> getTimestamp >>= loadValue k tmap
    Just (v, _) -> pure v

-- | Fetch a reasonably up-to-date version of the value.
--
-- This function is the most weird of all, but it hits a pretty nice
-- spot between the others. It will see if the cached value is outdated
-- and if it is, it will see if there is already a loading request for
-- a newer version running, and if there is, it will return the same
-- result. So, if the currently cached result is outdated, this function
-- will provide something better, but it /might/ happen that what it
-- returns is still somewhat outdated.
--
-- The great thing about this function is that it avoids starting new loading
-- actions if there are already some running that are not too old.
fetchBundled
  :: forall k v m
  .  ( Eq k, Hashable k
     , MonadIO m
     )
  => k -> ASTMap k v m -> m v
fetchBundled k tmap@ASTMap{amValues, amInvalid, amLoadStarted} = do
    mv <- atomically $ do
      invTime <- fromMaybe 0 <$> Map.lookup k amInvalid
      mres <- Map.lookup k amValues
      case mres of
        Just (v, vTime) | vTime > invTime -> pure $ Just v  -- great success!
        _ -> do
          mloadTime <- Map.lookup k amLoadStarted
          case (mloadTime, mres) of
            (Just loadTime, Nothing) -> Just <$> waitForOtherResult loadTime
            (Just loadTime, Just (_, vTime))
              | loadTime > vTime -> Just <$> waitForOtherResult loadTime
            _ -> pure Nothing  -- no one is loading it or they started too long ago
    -- XXX:
    -- Strictly speaking, it would be better to atomically ???lock??? the loading slot
    -- above, because currently it is possible that someone else starts loading
    -- the value at this point, so there will be to loads in parallel.
    case mv of
      Nothing -> getTimestamp >>= loadValue k tmap
      Just v -> pure v
  where
    -- | Wait for a value with timestamp at least @atTime@
    -- (we know someone is loading it)
    waitForOtherResult atTime =
      Map.lookup k amValues >>= \case
        Just (v, vTime) | vTime >= atTime -> pure v
        _ -> retry

-- | Fetch a value that may be outdated, but gather a new one in the background
-- if needed.
--
-- This function will check whether a value is being loaded, and if it is, it
-- will return the previously cached value and start loading a new one in the
-- background. If no value is being loaded, it will return the most recent
-- cached version, if it exists, however, if such value is invalid it will start
-- loading in the background as well. If no cached version exists, then it will
-- load and return it when it's done.
--
-- This means that it will always return some value, that may be invalid or not,
-- and will load a new one if needed. Fast, but may be innacurate.
--
-- TODO: Think of a better name for this function.
fetchFast
  :: forall k v m
  .  ( Eq k, Hashable k
     , MonadUnliftIO m
     )
  => k -> ASTMap k v m -> m v
fetchFast = fetchFastAndNotify (const $ pure ())

-- | Just like 'fetchFast', but also runs an action after it has finished
-- loading.
fetchFastAndNotify
  :: forall k v m
  .  ( Eq k, Hashable k
     , MonadUnliftIO m
     )
  => (v -> m ()) -> k -> ASTMap k v m -> m v
fetchFastAndNotify notify k tmap@ASTMap{amInvalid, amLoadStarted, amValues, amWorkers} = do
  mv <- atomically do
    invTime <- fromMaybe 0 <$> Map.lookup k amInvalid
    mres <- Map.lookup k amValues
    mLoadTime <- Map.lookup k amLoadStarted
    case mres of
      -- We have no option other than to load it and wait, or wait for someone
      -- else to finish loading it.
      Nothing -> maybe (pure Nothing) (const retry) mLoadTime
      Just (v, vTime)
        -- Success.
        | vTime > invTime -> pure $ Just (v, False)
        -- Invalid, but at least there is a cached result. Return it and load a
        -- new one in the background.
        | otherwise -> pure $ Just (v, True)

  let load = do
        time <- getTimestamp
        v <- loadValue k tmap time
        v <$ notify v
  case mv of
    Nothing -> load
    Just (v, shouldLoad) -> v <$ when shouldLoad do
      mWorker <- atomically $ Map.focus Focus.lookupAndDelete k amWorkers
      maybe (pure ()) cancel mWorker
      worker <- async load
      atomically $ Map.insert worker k amWorkers

-- | A 'Focus' that will insert a value if none was present or use the
-- one that is newer based on the function that returns the timestamp.
-- Returns @True@ if our value was inserted or has a newer timestamp..
--
-- If the timestamps match (impossible), choose the value that is being
-- inserted last.
insertOrChooseNewer :: Monad m => (v -> Timestamp) -> v -> Focus v m Bool
insertOrChooseNewer timestampOf vNew =
  Focus.cases (True, Focus.Set vNew) $ \vOld ->
    case compare (timestampOf vNew) (timestampOf vOld) of
      LT -> (False, Focus.Leave)
      _  -> (True, Focus.Set vNew)
