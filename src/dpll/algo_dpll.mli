open Clause
open Formule
open Algo

type etat

type formule

val name : string

val init : int -> int list list -> formule

val undo : formule -> etat -> etat (* défait k tranches d'assignations *)
  
val make_bet : formule -> literal -> etat -> etat (* fait un pari et propage *)
  
val continue_bet : formule -> literal -> etat -> etat (* poursuit la tranche du haut*)
  
val conflict_analysis : formule -> etat -> clause -> (literal*int) (* analyse le conflit trouvé dans la clause *)

val get_formule : formule -> Formule.formule
