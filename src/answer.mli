open Formule

type t = Unsolvable | Solvable of bool vartable

val check : int -> int list list -> t -> unit
 
val print_valeur : out_channel -> int -> bool -> unit

val print_answer : out_channel -> t -> unit 
