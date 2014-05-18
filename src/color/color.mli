open Reduction
open Answer

type t

val parse : in_channel -> t

val to_cnf : t -> int -> (bool*string) list list

val reduction : t -> 
