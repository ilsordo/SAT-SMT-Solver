class reduction : (reduction -> Answer.answer -> unit) -> 
object  
  method max : int
  
  method bind : string -> int

  method get_value : string -> int option

  method get_name : int -> string option

  method iter : (string -> int -> unit) -> unit

  method print_answer : out_channel -> Answer.answer -> unit
  
end

val renommer : (bool*string) list list -> (out_channel -> reduction -> Answer.answer -> unit) -> (int list list*reduction)

class ['a] counter : int -> (int -> 'a) ->
object
  method next : 'a
end







