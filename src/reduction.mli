type print_answer_t = out_channel -> Answer.t -> unit


module Reduction : (sig type t val val print_value : t -> string end) ->
sig
  class reduction : (reduction -> print_answer_t) ->
  object  
    method max : int
      
    method bind : Base.t -> int

    method get_id : Base.t -> int option

    method get_value : int -> Base.t option

    method iter : (Base.t -> int -> unit) -> unit

    method print_answer : print_answer_t
      
    method print_reduction : out_channel -> unit
  end

  val renommer : (bool*Base.t) list list -> (reduction -> print_answer_t) -> (int list list*reduction)
end

class ['a] counter : int -> (int -> 'a) ->
object
  method next : 'a
end











