open Formule

type t = Unsolvable | Solvable of bool vartable*(out_channel -> unit)

val check : int -> int list list -> t -> unit

val print_answer : out_channel -> t -> unit 
