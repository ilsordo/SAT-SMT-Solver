open Clause

class clauseset :
  object
    method add : clause -> unit
    method hide : clause -> unit
    method is_empty : bool
    method iter : (clause -> unit) -> unit
    method fold : 'a.(clause -> 'a -> 'a) -> 'a -> 'a 
    method mem : clause -> bool
    method show : clause -> unit
  end

class ['a] vartable :
  int ->
  object
    method iter : (variable -> 'a -> unit) -> unit
    method find : variable -> 'a option
    method mem : variable -> bool
    method remove : variable -> unit
    method set : variable -> 'a -> unit
    method size : int
  end

class formule :
  int ->
  variable list list ->
  object
    method get_nb_vars : int
    method get_pari : variable -> bool option
    method get_paris : bool vartable
    method add_clause : clause -> unit
    method get_clauses : clauseset
    method set_val : bool -> variable -> bool
    method reset_val : variable -> unit
    method find_singleton : (variable*bool) list
    method find_single_polarite : (variable*bool) option
  end
