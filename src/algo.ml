open Clause
open Formule
open Debug
open Answer

(* Note : Que mettre dans etat? *)

type tranche = literal * literal list 

type result = Fine | Backtrack (* | Deep_backtrack of int *)

module type Algo_base =
sig
  type formule

  type etat

  val name : string

  val init : int -> int list list -> (formule*etat)

  val constraint_propagation : formule -> literal -> etat

  (* Que faire en cas de conflit ? *)
  val recover : unit -> result

  (* Défait une tranche d'assignations *)
  val undo : formule -> etat -> etat
end

type t = Heuristic.t -> int -> int list list -> Answer.t 

exception Conflit of literal list

let neg : literal -> literal = function (b,v) -> (not b, v)

module Bind = functor(Base : Algo_base) ->
struct
  let algo next_pari n cnf =
    let (formule,etat) = Base.init n cnf in
    
    let rec process etat first lit = (* Ici réside toute la magie *)
      try
        debug#p 2 "%s : Starting propagation" Base.name;
        let etat = Base.constraint_propagation formule lit in (* lève une exception si conflit créé, sinon renvoie liste des vars assignées *)
        match aux etat with
          | Fine -> Fine
          | Backtrack when first ->
              let etat = undo formule etat in
              process etat false (neg lit)
          | Backtrack -> (* On a déjà fait le pari sur le littéral opposé, il faut remonter *)
              let _ = undo formule etat in
              Backtrack
        (* Ici on peut ajouter le code pour les backtracks en profondeur *)
      with
        | Conflit l -> recover () 
    
    and aux etat =
      stats#start_timer "Decision (heuristic) (s)";
      let lit = next_pari (formule:>formule) in
      stats#stop_timer "Decision (heuristic) (s)";
      match lit with
        | None -> 
            Fine (* plus rien à parier = c'est gagné *)
        | Some lit ->  
            stats#record "Paris";
            debug#p 2 "%s : Next bet = %d %B" Base.name var b;
            process etat true lit in
    match aux etat with
      | Fine -> Solvable formule#get_paris
      | Backtrack -> Unsolvable
end
















