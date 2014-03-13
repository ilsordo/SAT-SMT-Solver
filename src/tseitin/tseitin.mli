type tseitin_formule =
  | Var of string
  | And of tseitin_formule*tseitin_formule (* et *)
  | Or of tseitin_formule*tseitin_formule  (* ou *)
  | Imp of tseitin_formule*tseitin_formule (* implication *)
  | Equ of tseitin_formule*tseitin_formule (* on gère même l'équivalence ! *)
  | Not of tseitin_formule                 (* négation *)


(*val parse : in_channel -> tseitin_formule*)
val to_cnf : tseitin_formule -> (bool*string) list list




