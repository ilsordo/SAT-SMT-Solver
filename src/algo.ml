open Clause
open Formule
open Debug
open Answer

(* Note : Que mettre dans etat? *)

type tranche = literal * literal list 

type result = Fine | Backtrack (* | Deep_backtrack of int *)

module type Algo_base =
sig
  (* Information nécessaire à l'algorithme, peut contenir la formule *)
  type etat

  val name : string

  val init : int -> int list list -> etat

  (* Effectue le pari sur le littéral et propage les contraintes *)
  val make_bet : literal -> etat -> etat

  (* Défait une tranche d'assignations *)
  val undo : etat -> etat

  val get_formule : etat -> formule
end

type t = Heuristic.t -> int -> int list list -> Answer.t 

exception Conflit of literal list

let neg : literal -> literal = function (b,v) -> (not b, v)

module Bind = functor(Base : Algo_base) ->
struct
  let algo next_pari n cnf =

    let rec process etat first lit = (* Ici réside toute la magie *)
      try
        debug#p 2 "%s : Starting propagation" Base.name;
        let etat = Base.make_bet lit etat in (* lève une exception si conflit créé, sinon renvoie liste des vars assignées *)
        match aux etat with
          | Fine -> Fine
          | Backtrack when first ->
              let etat = undo etat in
              process etat false (neg lit)
          | Backtrack -> (* On a déjà fait le pari sur le littéral opposé, il faut remonter *)
              let _ = undo  etat in
              Backtrack
      (* Ici on peut ajouter le code pour les backtracks en profondeur *)
      with Conflit l ->
        let etat = undo formule etat in
        if first then
          process etat false (neg lit)
        else
          Backtrack
                
    and aux etat =
      stats#start_timer "Decision (heuristic) (s)";
      let lit = next_pari (get_formule etat) in
      stats#stop_timer "Decision (heuristic) (s)";
      match lit with
        | None -> 
            Fine (* plus rien à parier = c'est gagné *)
        | Some lit ->  
            stats#record "Paris";
            debug#p 2 "%s : Next bet = %d %B" Base.name var b;
            process etat true lit in

    try
      let etat = Base.init n cnf in
      match aux etat with
        | Fine -> Solvable ((get_formule etat)#get_paris)
        | Backtrack -> Unsolvable
    with Conflit -> Unsolvable (* Le prétraitement à détecté un conflit *)
end

















