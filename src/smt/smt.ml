open Formula_tree
open Clause
open Algo
open Smt_base

type answer 

module Make_smt = functor(Dpll : Algo_base) -> functor (Smt : Smt_base) ->
struct
  
  module Reduction = Reduction(struct type t = Base.atom let print_value = print_atom end)
  
  let algo (data : atom formula_tree) heuristic period cl interaction =
    
    (* Faire un pari, propager, se relever en cas de conflit *)
    let rec aux reduction etat_smt next_bet period date acc =
      match next_bet () with
        | No_bet (backtrack) ->
            begin
              try
                let etat_smt = Smt.propagate reduction (List.rev acc) etat_smt in
                etat_smt (** Sortie *)
              with
                | Conflit_smt (clause,etat_smt) -> (** clause * etat_smt ?? *)
                    let (undo_list,next_bet) = backtrack clause in
                    let etat_smt = Smt.backtrack reduction undo_list etat_smt in
                    aux reduction etat_smt next_bet period 0 []
            end
        | Bet_done (assignations,next_bet,backtrack) -> 
            let acc = assignations@acc in (** !! je pense que c'est dans cet ordre *)
            if date = period then (* c'est le moment de propager dans la théorie *)
              begin
                try
                  let etat_smt = Smt.propagate reduction (List.rev acc) etat_smt in 
                  aux reduction etat_smt next_bet period (date+1) []
                with
                  | Conflit_smt (clause,etat_smt) ->
                      let (undo_list,next_bet) = backtrack clause in
                      let etat_smt = Smt.backtrack reduction undo_list etat_smt in
                      aux reduction etat_smt next_bet period 0 []      
              end        
            else
              aux reduction etat_smt next_bet period (date+1) acc
        | Conflit_dpll (undo_list,next_bet) -> (* on suppose ici que dpll a déjà backtracké dans son coin *)
            let etat_smt = Smt.backtrack reduction undo_list etat_smt in
            aux reduction etat_smt next_bet period 0 []  
    in
    
    let data = Base.normalize data in (* normalisation de la formule donnée en entrée *)
    let (cnf_raw,next_free) = to_cnf data in (* transformation en cnf *)
    let (cnf, reduction) = Reduction.renommer ~start:next_free cnf_raw (function _ _ _ -> ()) in (* renommage pour avoir une cnf de int *)
    let etat_smt = Smt.init reduction in (* initialisation de l'etat du smt *)
    try 
      let (prop_init, next_bet) = Dpll.run heuristic cl interaction Smt.pure_prop reduction#count cnf in
      let etat_smt = Smt.propagate reduction prop_init etat_smt in
      aux reduction etat_smt next_bet period 1 []
    with
      | Conflit_smt _ 
      | Unsat -> Unsolvable










