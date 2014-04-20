open Clause
open Formule
open Algo

type formule

val name : string

val init : int -> int list list -> formule

val undo : ?depth:int -> formule -> etat -> etat
  
val make_bet : formule -> literal -> etat -> etat

val continue_bet : formule -> literal -> clause -> etat -> etat

val conflict_analysis : formule -> etat -> clause -> (literal*int*clause)

val get_formule : formule -> Formule.formule
