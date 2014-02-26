type variable = int

type c_repr

class varset :
object ('a)
  method repr : c_repr
  method add : variable -> unit
  method hide : variable -> unit
  method intersects : 'a -> bool
  method union : 'a -> 'a
  method is_empty : bool
  method size : int
  method mem : variable -> bool
  method show : variable -> unit
  method singleton : variable option
  method iter : (variable -> unit) -> unit
end

class clause :
  int ref -> variable list ->
object
  val vneg : varset
  val vpos : varset
  method get_id : int
  method get_vneg : varset
  method get_vpos : varset
  method get_vars : varset
  method hide_var : bool -> variable -> unit
  method is_empty : bool
  method is_tauto : bool
  method mem : bool -> variable -> bool
  method singleton : (variable*bool) option
  method show_var : bool -> variable -> unit
end

module OrderedClause : sig
  type t = clause
  val compare : clause -> clause -> int
end









