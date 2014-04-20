open Clause
open Formule
open Debug
open Answer

type tranche = literal * literal list 

type 'a result = Fine of 'a | Backtrack of 'a

type t = Heuristic.t -> bool -> int -> int list list -> Answer.t

let neg : literal -> literal = function (b,v) -> (not b, v)

type etat = {
  tranches : tranche list;
  level : int
}

exception Conflit_prop of (clause*(literal list)) (* permet de construire une tranche quand conflit trouvé dans prop *)

exception Conflit of (clause*etat)



module type Algo_base =
sig
  type formule

  val name : string

  val init : int -> int list list -> formule

  val undo : ?depth:int -> formule -> etat -> etat (* défait k tranches d'assignations *)
  
  val make_bet : formule -> literal -> etat -> etat (* fait un pari et propage *)
  
  val continue_bet : formule -> literal -> clause -> etat -> etat (* poursuit la tranche du haut*)
  
  val conflict_analysis : formule -> etat -> clause -> (literal*int*clause) (* analyse le conflit trouvé dans la clause *)

  val get_formule : formule -> Formule.formule
end





module Bind = functor(Base : Algo_base) ->
struct
  let algo next_pari cl n cnf = (* cl : activation du clause learning *)

    let rec process formule etat first ((b,v) as lit) = (* effectue un pari et propage le plus loin possible *)
      try
        debug#p 2 "Setting %d to %B (level : %d)" v b (etat.level+1);
        let etat = Base.make_bet formule lit etat in (* lève une exception si conflit créé *)
          match aux formule etat with (* lève erreur ici pour cl*)
            | Fine etat -> Fine etat
            | Backtrack etat when first -> (* ça arrive ça ?*)
                debug#p 2 "Backtrack : trying negation";
                let etat = Base.undo formule etat in
                  process formule etat false (neg lit)
            | Backtrack etat -> (* On a déjà fait le pari sur le littéral opposé, il faut remonter *)
                debug#p 2 "Backtrack : no options left, backtracking";
                Backtrack (Base.undo formule etat) (* on fait sauter une deuxième tranche ? *)                 
      with 
        | Conflit (c,etat) ->
              stats#record "Conflits";
              debug#p 2 ~stops:true  "Impossible bet : clause %d false" c#get_id;
              debug#p 2 "Conflit : %a" c#print ();
              (** ICI : graphe/dérivation en regardant la dernière tranche // update infos sur nb de conflits/srestart/decision/vieillissement *)
              if (not cl) then (* ici : du clause learning ou pas *)
                begin
                  let etat = Base.undo formule etat in (*on fait sauter la tranche, qui contient tous les derniers paris *)(* ici, il faut rétablir le bon level*)
                  if first then
                    process formule etat false (neg lit)
                  else
                    Backtrack etat
                end
              else
                begin
                  stats#start_timer "Clause learning (s)";
                  let ((b,v),k,c_learnt) = Base.conflict_analysis formule etat c in
                  debug#p 2 "%a" c_learnt#print ();
                  stats#stop_timer "Clause learning (s)";
                  debug#p 2 "Reaching level %d to set %B %d (origin : learnt clause %d)" k b v c_learnt#get_id;
                  let btck_etat = Base.undo ~depth:(etat.level-k) formule etat in
                    aux formule (Base.continue_bet formule (b,v) c_learnt btck_etat)
                end
                
    and aux formule etat =
      debug#p 2 "Seeking next bet";
      stats#start_timer "Decision (heuristic) (s)";
      let lit = next_pari (Base.get_formule formule) in
      stats#stop_timer "Decision (heuristic) (s)";
      match lit with
        | None ->
            debug#p 2 "No bets found";
            Fine etat (* plus rien à parier = c'est gagné *)
        | Some ((b,v) as lit) ->  
            stats#record "Paris";
            debug#p 2 "Next bet : %d %B" v b;
            process formule etat true lit in

    try
      let formule = Base.init n cnf in
      let etat = { tranches = []; level = 0 } in
      match aux formule etat with
        | Fine etat -> Solvable ((Base.get_formule formule)#get_paris)
        | Backtrack _ -> Unsolvable
    with Unsat -> Unsolvable (* Le prétraitement à détecté un conflit // ou Clause learning *)
end






