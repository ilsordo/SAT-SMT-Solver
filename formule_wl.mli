open Clause
open Formule

type wl_update = WL_Conflit | WL_New| WL_Assign of literal | WL_Nothing

class formule_wl :
object
  method watch : clause -> literal -> literal -> unit
  method get_wl_pos : variable -> clauseset
  method get_wl_neg : variable -> clauseset
  method get_wl : variable -> clauseset vartable -> clauseset
  method init_wl : unit
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
  method update_clause : clause -> literal -> wl_update 
end
