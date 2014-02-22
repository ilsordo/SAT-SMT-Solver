open Clause

class clauseset :
  object
    method add : clause -> unit
    method hide : clause -> unit
    method is_empty : bool
    method iter : (clause -> unit) -> unit
    method filter : (clause -> bool) -> clause list
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
    val nb_vars : int
    val clauses : clauseset
    val occurences_neg : clauseset vartable
    val occurences_pos : clauseset vartable
    val paris : bool vartable
    method get_nb_vars : int
    method set_pari : variable -> bool -> unit
    method is_pari : variable -> bool
    method get_pari : variable -> bool
    method add_clause : clause -> unit
    method get_clauses : clauseset
    method reset_val : variable -> unit
    method set_val : bool -> variable -> unit
    method find_singleton : variable list
    method find_single_polarite : (variable*bool) option
  end
