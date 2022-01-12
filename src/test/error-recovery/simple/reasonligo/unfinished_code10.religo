type commit = { date : timestamp, salted_hash : bytes }

type commit_set = big_map (address, commit)

type storage =
{ hashed : bytes, unused : bool, commits : commit_set }

type reveal =
{ hashable : bytes, message : (unit => list (oparation)) } // look here

type parameter = Commit (bytes) | Reveal (reveal)

type return = (list (operation), storage)
/* We use hash-commit so that a baker can not steal */

let commit = (p, s : (bytes, storage)) : return =>
  let commit : commit =
    { date : Tezos.now + 86400, salted_hash : p };
  let updated_map : commit_set =
    Big_map.update(Tezos.sender, Some (commit), s.commits);
  let s = {...s, commits : updated_map};
  ([] : list(operation), s)

let reveal = (p, s : (reveal, storage)) : return =>
  if (!s.unused) {
    (failwith ("This contract has already been used.")
     : return)
  }
  else {
    let commit : commit =
      switch (Big_map.find_opt (sender, s.commits)) {
      /* TODO */
      };
    if (Tezos.now < commit.date) {
      (failwith
         ("It has not been 24 hours since your commit yet.")
       : return)
    }
    else {
      let salted =
        Crypto.sha256
          (Bytes.concat (p.hashable, Bytes.pack (sender)));
      if (salted != commit.salted_hash) {
        (failwith
           ("This reveal does not match your commitment.")
         : return)
      }
      else {
        if (s.hashed == Crypto.sha256 (p.hashable)) {
          let s : storage = {...s, unused : false};
          (p.message (), s)
        }
        else {
          (failwith
             ("Your commitment did not match the storage hash.")
           : return)
        }
      }
    }
  }

let main = (p, s : (parameter, storage)) : return =>
  switch p {
    | Commit c => commit (c, s)
    | Reveal r => reveal (r, s)
  }