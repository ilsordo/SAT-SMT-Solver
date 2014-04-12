open Clause
open Formule
open Debug
open Answer

(* Note : Que mettre dans etat? *)

type tranche = literal * literal list 

type 'a result = Fine of 'a | Backtrack of 'a (* | Deep_backtrack of int*'a *)

module type Algo_base =
sig
  (* Information nécessaire à l'algorithme, peut contenir la formule *)
  type etat

  val name : string

  val init : int -> int list list -> etat

  (* Effectue le pari sur le littéral et propage les contraintes *)
  val make_bet : literal -> etat -> etat

  (* Défait une tranche d'assignations en cas de conflit *)
  val recover : tranche -> etat -> etat

  val undo : etat -> etat

  val get_formule : etat -> formule
end

type t = Heuristic.t -> int -> int list list -> Answer.t

exception Conflit of literal list

let neg : literal -> literal = function (b,v) -> (not b, v)

module Bind = functor(Base : Algo_base) ->
struct
  let algo next_pari n cnf =

    let rec process etat first ((b,v) as lit) = (* Ici réside toute la magie *)
      try
        debug#p 2 "Setting %d to %B" v b;
        let etat = Base.make_bet lit etat in (* lève une exception si conflit créé, sinon renvoie liste des vars assignées *)
        match aux etat with
          | Fine etat -> Fine etat
          | Backtrack etat when first ->
              debug#p 2 "Backtrack : trying negation";
              let etat = Base.undo etat in
              process etat false (neg lit)
          | Backtrack etat -> (* On a déjà fait le pari sur le littéral opposé, il faut remonter *)
              debug#p 2 "Backtrack : no options left, backtracking";
              Backtrack (Base.undo etat)
      (* Ici on peut ajouter le code pour les backtracks en profondeur *)
      with Conflit l ->
        debug#p 2 "Impossible bet";
        let etat = Base.recover (lit,l) etat in
        if first then
          process etat false (neg lit)
        else
          Backtrack etat
                
    and aux etat =
      debug#p 2 "Seeking next bet";
      stats#start_timer "Decision (heuristic) (s)";
      let lit = next_pari (Base.get_formule etat) in
      stats#stop_timer "Decision (heuristic) (s)";
      match lit with
        | None ->
            debug#p 2 "No bets found";
            Fine etat (* plus rien à parier = c'est gagné *)
        | Some ((b,v) as lit) ->  
            stats#record "Paris";
            debug#p 2 "Next bet = %d %B" v b;
            process etat true lit in

    try
      let etat = Base.init n cnf in
      match aux etat with
        | Fine etat -> Solvable ((Base.get_formule etat)#get_paris)
        | Backtrack _ -> Unsolvable
    with Conflit _ -> Unsolvable (* Le prétraitement à détecté un conflit *)
end

















