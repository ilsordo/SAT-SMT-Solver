
val parse : in_channel -> int*(int list list)

val to_cnf : int*(int list list) -> int*(int list list)

val print_answer : out_channel -> Answer.t -> unit
