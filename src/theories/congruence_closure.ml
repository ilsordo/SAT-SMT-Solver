open Formula_tree
open Union_find

type term = Var of string | Fun of term*term

type atom = Eq of term*term | Ineq of term*term


let parse_atom s =
  ...
  
let print_atom p a = 
  ...


(*
  normalize : map temporaire pour renommer



*)
