type storage is int

type parameter is list (int)

type return is list (operation) * storage

function hd (const x : list (int)) : int is
  if x = nil
    -1
  else
    hd (x)


function main (const a: parameter; const b: storage) : return is
  ((nil : list (operation)), (hd (a) + (b + 8) * 11))
