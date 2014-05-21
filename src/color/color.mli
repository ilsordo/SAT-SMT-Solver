open Reduction
open Answer

type t

val parse : in_channel -> t

val to_cnf : t -> int -> (bool*string super_atom) list list

val print_answer : int -> t -> string reduction -> out_channel -> Answer.t -> unit
