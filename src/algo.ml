open Clause
open Formule
open Debug
open Answer
open Interaction
open Algo_base
open Algo_parametric
open Printf

type t = Heuristic.t -> bool -> bool -> int -> (bool*int) list list -> Answer.t

let print_valeur p v = function (* affichage d'une variable (int) et de sa valeur *)
  | true -> fprintf p "v %d\n" v
  | false -> fprintf p "v -%d\n" v

exception Conflit of (clause*etat)

module Bind = functor(Base : Algo_base) ->
struct
  module Algo = Algo_parametric.Bind ( Base )
    
  let algo (next_pari : Heuristic.t) cl interaction n cnf =
    
    let rec aux next_bet =
      match next_bet () with
        | No_bet (values,_) -> Solvable (values,fun p -> values#iter (print_valeur p))
        | Bet_done (_,next_bet,_)
        | Conflit_dpll (_,next_bet) -> aux next_bet in

    try
      let (_,next_bet) = Algo.run next_pari cl interaction true n cnf in
      aux next_bet
    with
      | Unsat -> Unsolvable
end



















