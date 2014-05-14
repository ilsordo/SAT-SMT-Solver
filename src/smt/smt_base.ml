open Formula
open Clause

exception Conflit_smt of (literal list) (* Clause à apprendre *)

module type Smt_base =
sig
(* Langage de la théorie*)
  type atom

  val parse_atom : string -> atom option

  val print_atom : out_channel -> atom -> unit

(* Théorie *)

  type etat

  val init : atom formula -> (etat*int*int list list)

(* Enregistre une ou plusieurs tranches de Dpll et propage selon la théorie, lève Conflit_smt *)
  val propagate : literal list -> etat -> etat

(* Défait les assignations, si l'une d'elle n'a pas été effectuée, ignore le littéral *)
  val backtrack : literal list -> etat -> etat

  val print_etat : out_channel -> etat -> unit
end
