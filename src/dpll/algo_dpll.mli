open Clause
open Formule
open Algo

type etat

val name : string

val init : int -> int list list -> etat

val make_bet : literal -> etat -> etat

val recover : tranche -> etat -> etat

val undo : etat -> etat

val get_formule : etat -> formule
