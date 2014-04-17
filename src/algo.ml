open Clause
open Formule
open Debug
open Answer

type tranche = literal * literal list 

type 'a result = Fine of 'a | Backtrack of 'a | Deep_backtrack of (literal*int*bool*'a)

type t = Heuristic.t -> int -> int list list -> Answer.t

let neg : literal -> literal = function (b,v) -> (not b, v)

exception Conflit_prop of (clause*(literal list)) (* permet de construire une tranche quand conflit trouvé dans prop *)

exception Conflit of (clause*etat)



module type Algo_base =
sig
  type etat

  val name : string

  val init : int -> int list list -> etat

  val undo : etat -> etat (* défait k tranches d'assignations *)
  
  val make_bet : literal -> etat -> etat (* fait un pari et propage *)
  
  val continue_bet : literal -> bool -> etat -> etat (* poursuit la tranche du haut*)
  
  val conflict_analysis : etat -> clause -> (literal*int*bool) (* analyse le conflit trouvé dans la clause *)

  val get_formule : etat -> formule
end





module Bind = functor(Base : Algo_base) ->
struct
  let algo next_pari ?(cl=false) n cnf =

    let rec process etat first ((b,v) as lit) = (* effectue un pari et propage le plus loin possible *)
      try
        debug#p 2 "Setting %d to %B" v b;
        let etat = Base.make_bet lit etat in (* lève une exception si conflit créé *)
        match aux etat with
          | Fine etat -> Fine etat
          | Backtrack etat when first -> (* ça arrive ça ?*)
              debug#p 2 "Backtrack : trying negation";
              process etat false (neg lit)
          | Backtrack etat -> (* On a déjà fait le pari sur le littéral opposé, il faut remonter *)
              debug#p 2 "Backtrack : no options left, backtracking";
              Backtrack (Base.undo etat) (* on fait sauter une deuxième tranche ? *)
          | Deep_backtrack ((b,v),k,sgt,etat) ->
              if etat.level = k then 
                aux (continue_bet (b,v) sgt etat)
              else
                Deep_backtrack ((b,v),k-1,sgt,Base.undo etat)
      with 
        | Conflit (c,etat) ->
              debug#p 2 "Impossible bet";
              (** ICI : on peut faire le clause learning en regardant la dernière tranche *)
              if (not cl) then (* ici : du clause learning ou pas *)
                begin
                  let etat = Base.undo etat in (* à ce niveau, on fait sauter la tranche, qui contient tous les derniers paris *)(* ici, il faut rétablir le bon level*)
                  if first then
                    process etat false (neg lit)
                  else
                    Backtrack etat
                end
              else
                let ((b,v),k,sgt) = conflict_analysis etat c in
                  Deep_backtrack ((b,v),k,sgt,etat)
                
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
        
    with Init_empty -> Unsolvable (* Le prétraitement à détecté un conflit *)
end

















