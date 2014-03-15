class renommage :
object  
  method max : int
  
  method bind : string -> int

  method get_value : string -> int option

  method get_name : int -> string option

  method iter : (string -> int -> unit) -> unit
  
end

val renommer : (bool*string) list list -> (int list list*renommage)

class ['a] counter : int -> (int -> 'a) ->
object
  method next : 'a
end







