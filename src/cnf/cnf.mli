
val parse : in_channel -> int*((bool*int) list list)

val to_cnf : int*((bool*int) list list) -> int*((bool*int) list list)

val print_answer : out_channel -> Answer.t -> unit
