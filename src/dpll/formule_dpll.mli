open Clause
open Formule

class formule_dpll :
object
  method init : int -> variable list list -> unit
  method get_nb_vars : int
  method get_pari : variable -> bool option
  method get_paris : bool vartable
  method add_clause : clause -> unit
  method get_clauses : clauseset
  method get_nb_occ : bool -> int -> int 
  method set_val : bool -> variable -> unit
  method reset_val : variable -> unit
  method find_singleton : (variable*bool) option
  method find_single_polarite : (variable*bool) option
  method check_empty_clause : unit
  method eval : bool
end
