

type atom = Var of string

let parse_atom s =
  ...
  
let print_atom p a = 
  ...

(* Théorie *)

type etat = unit

let normalize formula = formula
  
let init reduc = () 
  
let propagate reduc prop etat = etat
  
let backtrack reduc undo_list etat = etat

let print_etat reduc etat = 
  ...
  
let pure_prop = true

