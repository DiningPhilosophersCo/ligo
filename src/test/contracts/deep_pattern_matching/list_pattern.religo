let a =
  switch ([1]) { 
  | [] => 1
  | [ a, ...[b, ...[c, ...[]]]] => 2
  | _ => 3
  }