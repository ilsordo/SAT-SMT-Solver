type print_answer_t = out_channel -> Answer.answer -> unit

class reduction : (reduction -> print_answer_t) -> 
object  
  method max : int
  
  method bind : string -> int

  method get_value : string -> int option

  method get_name : int -> string option

  method iter : (string -> int -> unit) -> unit

  method print_answer : print_answer_t
end


val renommer : (bool*string) list list -> (reduction -> print_answer_t) -> (int list list*reduction)

class ['a] counter : int -> (int -> 'a) ->
object
  method next : 'a
end











