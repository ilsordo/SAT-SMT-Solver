open Clause
open Formule

type tranche = bool*literal * literal list (* littéral parié, liste des littéraux assignés en conséquence *)

type etat = {
  tranches : tranche list;
  level : int
}

exception Conflit_prop of (clause*(literal list)) (* permet de construire une tranche quand conflit trouvé dans prop *)

module type Algo_base =
sig
  type formule = private #formule

  val name : string

  val init : int -> int list list -> formule (* construction de la formule, prétraitement *)

  val constraint_propagation : formule -> literal -> etat -> literal list -> literal list

  val set_wls : formule -> clause -> literal -> literal -> unit (* Nom pas très générique mais compréhensible *)

end
