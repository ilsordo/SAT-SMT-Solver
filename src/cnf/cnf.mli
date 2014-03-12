type t

val parse : in_channel -> t
val to_cnf : t -> int list list
