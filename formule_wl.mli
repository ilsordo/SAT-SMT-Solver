open Clause
open Formule

type wl_update = WL_Conflit | WL_New of literal | WL_Assign of literal | WL_Nothing

class formule_wl :
object
  method init : int -> variable list list -> unit
  method get_nb_vars : int
  method get_pari : variable -> bool option
  method get_paris : bool vartable
  method add_clause : clause -> unit
  method get_clauses : clauseset
  method set_val : bool -> variable -> unit
  method reset_val : variable -> unit
  method find_singleton : (variable*bool) option
  method check_empty_clause : unit
  method eval : bool
  method private update_clause : clause -> literal -> wl_update 
end
