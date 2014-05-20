open Formule

type t = Unsolvable | Solvable of bool vartable*(out_channel -> unit)

val check : int -> (bool*int) list list -> t -> unit
