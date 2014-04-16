open Clause
open Formule
open Algo

type etat

exception Conflit of (literal*clause*etat)

val name : string

val init : int -> int list list -> etat

val undo : ?deep:int -> etat -> etat

val make_bet : literal -> etat -> bool -> etat 

val continue_bet : literal -> etat ->etat 

val conflict_analysis : etat -> clause -> (literal*int*clause) 

val get_formule : etat -> formule
