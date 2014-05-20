open Reduction
open Answer

type t

val parse : in_channel -> t

val to_cnf : t -> int -> (bool*string) list list

val print_answer : int -> t -> string reduction -> print_answer_t
