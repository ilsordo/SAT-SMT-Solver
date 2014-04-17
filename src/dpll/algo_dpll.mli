open Clause
open Formule
open Algo

type etat

exception Conflit of (clause*etat)

val name : string

val init : int -> int list list -> etat

val undo : etat -> etat

val make_bet : literal -> etat -> etat 

val continue_bet : literal -> bool -> etat -> etat 

val conflict_analysis : etat -> clause -> (literal*int*bool) 

val get_formule : etat -> formule
