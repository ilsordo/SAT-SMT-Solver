open Reduction
open Answer

type t

val parse : in_channel -> t

val to_cnf : t -> int -> (bool*string) list list

val print_answer : int -> int list list -> out_channel -> reduction -> answer -> unit




