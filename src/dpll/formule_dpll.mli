open Clause
open Formule

class formule_dpll :
object
  method init : int -> variable list list -> unit
  method get_nb_vars : int
  method get_pari : variable -> bool option
  method get_paris : bool vartable
  method clause_current_size : clause -> int
  method add_clause : clause -> unit
  method get_clauses : clauseset
  method get_nb_occ : bool -> int -> int 
  method set_val : bool -> variable -> clause option -> int option -> unit
  method reset_val : variable -> unit
  method find_singleton : (literal*clause) option
  method find_single_polarite : (literal*clause) option
  method check_empty_clause : bool
  method eval : bool
  method get_origin : variable -> clause option
  method new_clause : clause
end
