open Formula_tree
open Term_parser
open Term_lexer
open Clause
open Algo_parametric
open Smt_base
open Algo_base
open Reduction

module Make_smt = functor(Dpll : Algo_base) -> functor (Smt : Smt_base) ->
struct
  
  module Reduction = Reduction(struct type t = Smt.atom let print_value = Smt.print_atom end)
  
  let parse input = 
    let module Parser = Make_parser ( Smt ) in
    let module Lexer = Make_lexer ( Smt ) ( Parser ) in
    let lex = Lexer.from_channel input in
    Parser.main Lexer.token lex

  let reduce data =
    let data = Base.normalize data in (* normalisation de la formule donnée en entrée *)
    let (cnf_raw,next_free) = to_cnf data in (* transformation en cnf *)
    Reduction.renommer ~start:next_free cnf_raw (* renommage pour avoir une cnf de int *)

  let algo heuristic period cl interaction reduction _ cnf =
    
    (* Faire un pari, propager, se relever en cas de conflit *)
    let rec aux reduction etat_smt next_bet period date acc =
      match next_bet () with
        | No_bet (values,backtrack) ->
            begin
              try
                let etat_smt = Smt.propagate reduction (List.rev acc) etat_smt in
                Solvable (values, Smt.print_answer etat_smt reduction values)
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
    
    
    let etat_smt = Smt.init reduction in (* initialisation de l'etat du smt *)
    try 
      let (prop_init, next_bet) = Dpll.run heuristic cl interaction Smt.pure_prop reduction#count cnf in
      let etat_smt = Smt.propagate reduction prop_init etat_smt in
      aux reduction etat_smt next_bet period 1 []
    with
      | Conflit_smt _ 
      | Unsat -> Unsolvable

  let print_answer p = function
    | Unsolvable -> fprintf p "s UNSATISFIABLE\n"
    | Solvable (values, print_result) -> fprintf p "s SATISFIABLE\n%t%!" print_result


end
