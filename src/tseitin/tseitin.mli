type t

val parse : in_channel -> t
val to_cnf : t -> (bool*string) list list




