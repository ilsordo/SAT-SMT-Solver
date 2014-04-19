open Clause
open Formule
open Algo

type formule

val name : string

val init : int -> int list list -> formule

val undo : ?depth:int -> formule -> etat -> etat (* défait k tranches d'assignations *)
  
val make_bet : formule -> literal -> etat -> etat (* fait un pari et propage *)

val continue_bet : formule -> literal -> clause -> etat -> etat (* poursuit la tranche du haut*)

val conflict_analysis : formule -> etat -> clause -> (literal*int*clause) (* analyse le conflit trouvé dans la clause *)

val get_formule : formule -> Formule.formule
