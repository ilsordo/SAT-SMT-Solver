open Clause
open Formule

type backtrack = First | Var_depth of (int*literal) | Clause_depth of (int*clause)
(* indique comment backtracker : 
     First : inverser le premier first dispo
     Var_depth(k,l) : se rendre k level plus bas puis assigner l
     Clause_depth(k,c) : se rendre k level plus bas, puis dépiler le level k jusqu'avant que c ait deux littéraux non assignés, assigner le premier littéral de c rencontré
*)

type tranche = bool*literal * literal list (* littéral parié, liste des littéraux assignés en conséquence *)

type etat = {
  tranches : tranche list;
  level : int
}

exception Conflit_prop of (clause*(literal list)) (* permet de construire une tranche quand conflit trouvé dans prop *)

exception Unsat

module type Algo_base =
sig
  type formule = private #formule

  val name : string

  val init : int -> literal list list -> bool -> (formule*literal list) (* construction de la formule, prétraitement *)

  val constraint_propagation : bool -> formule -> literal -> etat -> literal list -> literal list

  val set_wls : formule -> clause -> literal -> literal -> unit (* Nom pas très générique mais compréhensible *)

end
