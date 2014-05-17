open Clause
open Formule
open Algo_base

exception Conflit of (clause*etat)

type dpll_answer = 
  | No_bet of bool vartable * (literal list -> (literal list*(unit -> dpll_answer)))
  | Bet_done of literal list * (unit -> dpll_answer) * (literal list -> (literal list*(unit -> dpll_answer)))
  | Conflit_dpll of literal list * (unit -> dpll_answer)

module Bind : functor(Base : Algo_base) ->
sig
  
  val run : Heuristic.t -> bool -> bool -> bool -> int -> int list list -> (literal list * (unit -> dpll_answer))

end
