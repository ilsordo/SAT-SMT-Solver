open Formula_tree
open Clause
open Reduction
open Formule

module type Smt_base =
sig

  type atom (* les atomes sont normalisés lors du parsing *)

(* parsing des atomes de la théorie *)
  val parse : Lexing.lexbuf -> atom formula_tree

  val print_atom : out_channel -> atom -> unit

(* état de la théorie *)
  type etat

(* clause à apprendre suite à conflit dans la théorie *)
  exception Conflit_smt of (literal list*etat)

(* initialiser la théorie *)
  val init : atom reduction -> etat

(* propager dans la théorie une liste de littéraux assignés par dpll. Peut lever Conflit_smt *)
  val propagate : atom reduction -> literal list -> etat -> etat

(* backtrack dans la théorie *)
  val backtrack : atom reduction -> literal list -> etat -> etat

(* afficher le modèle *)
  val print_answer : atom reduction -> etat -> bool vartable -> out_channel -> unit

(* activation ou non de la propagation pure *)
  val pure_prop : bool
end
