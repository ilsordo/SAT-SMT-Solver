open Formule

type answer = Unsolvable | Solvable of bool vartable

val check : int -> int list list -> answer -> unit
 
val print_valeur : out_channel -> int -> bool -> unit

val print_answer : out_channel -> answer -> unit 
