type print_answer_t = out_channel -> Answer.t -> unit

type 'a super_atom = Real of 'a | Virtual of int

class type ['a] reduction =
object
  method max : int
    
  method bind : 'a -> int

  method get_id : 'a -> int option

  method get_orig : int -> 'a option

  method iter : ('a -> int -> unit) -> unit

  method fold : ('a -> int -> 'b -> 'b) -> 'b -> 'b
  
  method print_answer : print_answer_t
    
  method print_reduction : out_channel -> unit
end

module Reduction : functor (Base : sig type t val print_value : t -> string end) ->
sig
  val reduction : ?start:int -> (Base.t reduction -> print_answer_t) -> Base.t reduction

  val renommer : (bool*Base.t) list list -> (Base.t reduction -> print_answer_t) -> (int list list*Base.t reduction)
end

class ['a] counter : int -> (int -> 'a) ->
object
  method next : 'a

  method count : int
end











