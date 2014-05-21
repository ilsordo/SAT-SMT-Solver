
type 'a super_atom = Real of 'a | Virtual of int

type 'a reduction =
<
  max : int;
    
  bind : 'a -> int;

  get_id : 'a -> int option;

  get_orig : int -> 'a option;

  iter : ('a -> int -> unit) -> unit;

  fold : 'b.('a -> int -> 'b -> 'b) -> 'b -> 'b;
    
  print_reduction : out_channel -> unit
>

module Reduction : functor (Base : sig type t val print_value : out_channel -> t -> unit end) ->
sig
  val reduction : int -> Base.t reduction

  val renommer : ?start:int -> (bool*Base.t super_atom) list list -> ((bool*int) list list*Base.t reduction)
end

class ['a] counter : int -> (int -> 'a) ->
object
  method next : 'a

  method count : int
end











