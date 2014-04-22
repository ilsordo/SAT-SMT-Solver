open Clause

exception Unsat

exception Empty_clause of clause

class clauseset :
object
  method size : int
  method mem : clause -> bool
  method add : clause -> unit
  method add_hid : clause -> unit
  method remove : clause -> unit
  method show : clause -> unit
  method hide : clause -> unit
  method is_empty : bool
  method reset : unit
  method iter : (clause -> unit) -> unit
  method iter_all : (clause -> unit) -> unit
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
  val origin : clause vartable
  val level : int vartable
  method init : int -> int list list -> unit 
  method get_nb_vars : int
  method get_pari : variable -> bool option
  method get_paris : bool vartable
  method add_clause : clause -> unit
  method clause_current_size : clause -> int
  method get_clauses : clauseset
  method get_nb_occ : bool -> int -> int
  method set_val : bool -> variable -> ?cl:clause -> int -> unit
  method reset_val : variable -> unit
  method find_singleton : (literal*clause) option
  method check_empty_clause : unit
  method eval : bool
  method get_origin : variable -> clause option
  method new_clause : clause
  method get_level : variable -> int
  method watch : clause -> literal -> literal -> unit (***)
end

















