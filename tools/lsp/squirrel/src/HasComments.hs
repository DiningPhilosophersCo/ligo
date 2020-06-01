
module HasComments
  ( HasComments(..)
  , c
  )
  where

import qualified Data.Text as Text

import Pretty

-- | Ability to contain comments.
class HasComments c where
  getComments :: c -> [Text.Text]

-- | Wrap some @Doc@ with a comment.
c :: HasComments i => i -> Doc -> Doc
c i d =
  case getComments i of
    [] -> d
    cc -> block (map removeSlashN cc) $$ d
  where
    removeSlashN txt =
      if "\n" `Text.isSuffixOf` txt
      then Text.init txt
      else txt

-- | Narrator: /But there was none/.
instance HasComments () where
  getComments () = []