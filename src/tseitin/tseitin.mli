open Reduction
open Answer

type t

val parse : in_channel -> t

val to_cnf : t -> (bool*string) list list

val print_answer : out_channel -> reduction -> answer -> unit
