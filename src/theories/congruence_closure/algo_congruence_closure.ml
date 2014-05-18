

type term = Var of string | Fun of term*term

type atom = Eq of term*term | Ined of term*term


let parse_atom s =
  ...
  
let print_atom p a = 
  ...


(*
  normalize : map temporaire pour renommer



*)
