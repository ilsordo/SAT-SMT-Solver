open Clause
open Formule
open Debug
open Answer

(* Note : Que mettre dans etat? *)

exception Conflit of (literal*clause*etat) (***)

exception Conflit_prop of (literal*clause*(literal list)) (***) (* permet de construire une tranche quand conflit trouvé dans prop *)

type tranche = literal * literal list 

type 'a result = Fine of 'a | Backtrack of 'a | Deep_backtrack of (clause*'a)

type t = Heuristic.t -> int -> int list list -> Answer.t

let neg : literal -> literal = function (b,v) -> (not b, v)




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




module Bind = functor(Base : Algo_base) ->
struct
  let algo next_pari n cnf ?(cl=false) =

    let rec process etat first ((b,v) as lit) lvl = (* un pari et on propage le + loin possible *)
      try
        debug#p 2 "Setting %d to %B" v b;
        let etat = Base.make_bet lit etat lvl in (* lève une exception si conflit créé *)
        match aux etat (lvl+1) with
          | Fine etat -> Fine etat
          | Backtrack etat when first -> (* ça arrive ça ?*)
              debug#p 2 "Backtrack : trying negation";
              process etat false (neg lit) lvl
          | Backtrack etat -> (* On a déjà fait le pari sur le littéral opposé, il faut remonter *)
              debug#p 2 "Backtrack : no options left, backtracking";
              Backtrack (Base.undo etat) (* on fait sauter une deuxième tranche ? *)
          | Deep_backtrack (c_learnt,etat) ... ->
              Base.undo etat c_learnt;
              let etat = continue_bet ... etat 
              (***...*)   
      with 
        | Conflit (l,c,etat) ->
            begin
              debug#p 2 "Impossible bet";
              if (not cl) then
                begin
                  let etat = Base.undo etat in (* à ce niveau, on fait sauter la tranche, qui contient tous les derniers paris *)
                  if first then
                    process etat false (neg lit)
                  else
                    Backtrack etat
                end
              else
                let (c_learnt,(b,v)) = conflict_analysis etat c in
                  Deep_backtrack (c_learnt,etat) (***)
            end
                
    and aux etat lvl =
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
            process etat true lit lvl in

    try
      let etat = Base.init n cnf in
      match aux etat 1 with
        | Fine etat -> Solvable ((Base.get_formule etat)#get_paris)
        | Backtrack _ -> Unsolvable
    with Init_empty -> Unsolvable (* Le prétraitement à détecté un conflit *)
end

















