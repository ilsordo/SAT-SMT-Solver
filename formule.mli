open Clause

class clauseset :
  object
    method add : clause -> unit
    method hide : clause -> unit
    method is_empty : bool
    method iter : (clause -> unit) -> unit
    method mem : clause -> bool
    method show : clause -> unit
  end

class ['a] vartable :
  int ->
  object
    method iter : (variable -> 'a -> unit) -> unit
    method mem : variable -> 'a option
    method remove : variable -> unit
    method set : variable -> 'a -> unit
    method size : int
  end

class formule :
  int ->
  variable list list ->
  object
    val clauses : clauseset
    val occurences_neg : clauseset vartable
    val occurences_pos : clauseset vartable
    val paris : bool vartable
    method add_clause : clause -> unit
    method get_clauses : clauseset
    method reset_val : variable -> unit
    method set_val : bool -> variable -> unit
  end
