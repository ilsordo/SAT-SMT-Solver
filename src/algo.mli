open Clause
open Formule

type t = Heuristic.t -> bool -> int -> int list list -> Answer.t

type tranche = literal * literal list 

type etat = {
  tranches : tranche list;
  level : int
}

exception Conflit_prop of (clause*(literal list)) (* permet de construire une tranche quand conflit trouvé dans prop *)

module type Algo_base =
sig
  type formule = private #formule (* J'ai trouvé! *)

  val name : string

  val init : int -> int list list -> formule (* construction de la formule, prétraitement *)

  val constraint_propagation : formule -> literal -> etat -> literal list -> literal list

  val set_wls : formule -> clause -> literal -> literal -> unit (* Nom pas très générique mais compréhensible *)

end

module Bind : functor (Base : Algo_base) -> 
sig
  val algo : t 
end
