type 'a formula =
  | And of ('a formula)*('a formula) 
  | Or of ('a formula)*('a formula)  
  | Imp of ('a formula)*('a formula) (* implication *)
  | Equ of ('a formula)*('a formula) (* équivalence *)
  | Not of ('a formula) 
  | Atom of 'a
