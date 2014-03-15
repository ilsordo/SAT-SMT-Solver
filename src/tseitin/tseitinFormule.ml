type t =
  | Var of string
  | And of t*t (* et *)
  | Or of t*t  (* ou *)
  | Imp of t*t (* implication *)
  | Equ of t*t (* on gère même l'équivalence ! *)
  | Not of t   (* négation *)
