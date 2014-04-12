open Clause

exception Clause_vide

class clauseset :
object
  method size : int
  method mem : clause -> bool
  method add : clause -> unit
  method remove : clause -> unit
  method show : clause -> unit
  method hide : clause -> unit
  method is_empty : bool
  method reset : unit
  method iter : (clause -> unit) -> unit
  method fold : 'a.(clause -> 'a -> 'a) -> 'a -> 'a 
  method choose : clause option
end

class ['a] vartable :
  int ->
object
  method iter : (variable -> 'a -> unit) -> unit
  method fold : 'b.(variable -> 'a -> 'b -> 'b) -> 'b -> 'b
  method find : variable -> 'a option
  method mem : variable -> bool
  method remove : variable -> unit
  method set : variable -> 'a -> unit
  method size : int
  method is_empty : bool
  method reset : unit
end

class formule :
object
  val clauses : clauseset
  val paris : bool vartable
  method init : int -> variable list list -> unit 
  method get_nb_vars : int
  method get_pari : variable -> bool option
  method get_paris : bool vartable
  method add_clause : clause -> unit
  method clause_current_size : clause -> int
  method get_clauses : clauseset
  method get_nb_occ : bool -> int -> int
  method set_val : bool -> variable -> unit
  method reset_val : variable -> unit
  method find_singleton : literal option
  method check_empty_clause : bool
  method eval : bool
end

















