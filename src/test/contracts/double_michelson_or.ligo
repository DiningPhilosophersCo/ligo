type storage is michelson_or (int, string)
type foobar is michelson_or (int, int)

type return is list (operation) * storage 

function main (const action : unit; const store : storage) : return is
block { 
  const foo : storage = (M_right ("one") : storage);
  const bar : foobar = (M_right (1) : foobar)
} with
 ((nil : list (operation)), (foo : storage))