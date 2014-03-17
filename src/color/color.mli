open Renommage
open Answer

type t

val parse : in_channel -> t

val to_cnf : t -> int -> (bool*string) list list

val print_answer : out_channel -> int ->  renommage -> int list list -> answer -> unit




