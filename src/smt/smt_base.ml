open Formula_tree
open Clause
open Reduction
open Formule

module type Smt_base =
sig
(* Langage de la théorie*)
  type atom

  val parse_atom : string -> atom formula_tree

  val print_atom : out_channel -> atom -> unit

(* Théorie *)

  type etat

  exception Conflit_smt of (literal list*etat) (* Clause à apprendre *)

  val normalize : atom formula_tree -> atom formula_tree

  val init : atom reduction -> etat

(* Enregistre une ou plusieurs tranches de Dpll et propage selon la théorie, lève Conflit_smt *)
  val propagate : atom reduction -> literal list -> etat -> etat

(* Défait les assignations, si l'une d'elle n'a pas été effectuée, ignore le littéral *)
  val backtrack : atom reduction -> literal list -> etat -> etat

  val print_answer : atom reduction -> etat -> bool vartable -> out_channel -> unit

  val pure_prop : bool
end
