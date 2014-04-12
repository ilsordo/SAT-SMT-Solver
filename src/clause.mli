type variable = int

type c_repr

type 'a classif = Empty | Singleton of 'a | Bigger

type literal = (bool * variable)

class varset :
object ('a)
  method repr : c_repr
  method add : variable -> unit
  method hide : variable -> unit
  method intersects : 'a -> bool
  method is_empty : bool
  method size : int
  method mem : variable -> bool
  method show : variable -> unit
  method singleton : variable classif
  method iter : (variable -> unit) -> unit
  method fold : 'a.(variable -> 'a -> 'a) -> 'a -> 'a 
end

class clause :
  int ref -> variable list ->
object
  method get_wl : literal*literal
  method set_wl1 : literal -> unit
  method set_wl2 : literal -> unit
  method get_id : int
  method get_vneg : varset
  method get_vpos : varset
  method hide_var : bool -> variable -> unit
  method show_var : bool -> variable -> unit
  method is_empty : bool
  method size : int
  method is_tauto : bool
  method mem : bool -> variable -> bool
  method singleton : literal classif
  method print : out_channel -> unit -> unit
end

module OrderedClause : sig
  type t = clause
  val compare : clause -> clause -> int
end









