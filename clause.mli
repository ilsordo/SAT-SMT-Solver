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
  method mem : variable -> bool
  method show : variable -> unit
  method singleton : variable option
  method iter : (variable -> unit) -> unit
end

class clause :
  variable list ->
object
  val vneg : varset
  val vpos : varset
  method get_vneg : varset
  method get_vpos : varset
  method get_vars : varset
  method hide_var : bool -> variable -> unit
  method is_empty : bool
  method is_tauto : bool
  method vars : varset
  method mem_neg : variable -> bool
  method mem_pos : variable -> bool
  method show_var : bool -> variable -> unit
end

module OrderedClause : sig
  type t = clause
  val compare : clause -> clause -> int
end









