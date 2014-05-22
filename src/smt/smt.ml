open Formula_tree
open Clause
open Algo_parametric
open Smt_base
open Algo_base
open Reduction
open Answer
open Formule
open Debug

module Make_smt = functor(Dpll : Algo_parametric) -> functor (Smt : Smt_base) ->
struct
  
  module Reduction = Reduction(struct type t = Smt.atom let print_value = Smt.print_atom end)

  let parse input = 
    let lexbuf = Lexing.from_channel input in
    Smt.parse lexbuf
  

  let reduce data =
    let (cnf_raw,next_free) = to_cnf data in (* transformation en cnf *)
    Reduction.renommer ~start:next_free cnf_raw (* renommage pour avoir une cnf de int *)

  let algo period reduction heuristic cl interaction _ cnf =
    
    (* Faire un pari, propager, se relever en cas de conflit *)
    let rec aux reduction etat_smt next_bet period date acc =
      match next_bet () with
        | No_bet (values,backtrack) -> (* on regarde si la théorie est consistante *)
            begin
              try
                stats#start_timer "SMT propagate (s)";
                let etat_smt = Smt.propagate reduction (List.rev acc) etat_smt in (* propagation dans la théorie *)
                stats#stop_timer "SMT propagate (s)";
                Solvable (values, Smt.print_answer reduction etat_smt values)
              with
                | Smt.Conflit_smt (clause,etat_smt) ->
                    stats#record "SMT conflicts";
                    stats#record "Learnt clauses";
                    stats#stop_timer "SMT propagate (s)";
                    let (undo_list,next_bet) = backtrack clause in (* backtrack dans dpll *)
                    stats#start_timer "SMT backtrack (s)";
                    let etat_smt = Smt.backtrack reduction undo_list etat_smt in (* backtrack dans la théorie *)
                    stats#stop_timer "SMT backtrack (s)";
                    aux reduction etat_smt next_bet period 0 []
            end
        | Bet_done (assignations,next_bet,backtrack) -> 
            let acc = assignations@acc in
            if date = period then (* c'est le moment de propager dans la théorie *)
              begin
                try
                  stats#start_timer "SMT propagate (s)";
                  let etat_smt = Smt.propagate reduction (List.rev acc) etat_smt in (* propagation dans la théorie *) 
                  stats#stop_timer "SMT propagate (s)";
                  aux reduction etat_smt next_bet period (date+1) []
                with
                  | Smt.Conflit_smt (clause,etat_smt) ->
                      stats#record "SMT conflicts";
                      stats#record "Learnt clauses";
                      stats#stop_timer "SMT propagate (s)";
                      let (undo_list,next_bet) = backtrack clause in (* backtrack dans dpll *)
                      stats#start_timer "SMT backtrack (s)";
                      let etat_smt = Smt.backtrack reduction undo_list etat_smt in (* backtrack dans la théorie *)
                      stats#stop_timer "SMT backtrack (s)";
                      aux reduction etat_smt next_bet period 0 []
              end        
            else
              aux reduction etat_smt next_bet period (date+1) acc
        | Conflit_dpll (undo_list,next_bet) -> (* on suppose ici que dpll a déjà backtracké dans son coin *)
            let rec update_acc started = function (* Extrait la tête de undo_list (qui n'a pas été enregistrée dans acc) puis la partie de undo_list qui est en tête de acc *)
              | [], acc -> ([], acc)
              | undo_list, [] -> (undo_list, [])
              | (t::undo_list), (t'::acc) when t = t' -> update_acc true (undo_list, acc)
              | undo_list, acc when started -> (undo_list, acc)
              | (_::undo_list), acc -> update_acc false (undo_list, acc) in
            stats#start_timer "SMT backtrack (s)";
            let (undo_list, acc) = update_acc false (undo_list, acc) in
            let etat_smt = Smt.backtrack reduction undo_list etat_smt in (* backtrack dans la théorie *)
            stats#stop_timer "SMT backtrack (s)";
            aux reduction etat_smt next_bet period 0 acc
    in
    
    
    let etat_smt = Smt.init reduction in (* initialisation de l'etat du smt *)
    try 
      let (prop_init, next_bet) = Dpll.run heuristic cl interaction Smt.pure_prop reduction#max cnf in (* prop init dans dpll *)
      stats#start_timer "SMT propagate (s)";
      let etat_smt = Smt.propagate reduction prop_init etat_smt in (* propagation dans la théorie *)
      print_int 77777777777;
      stats#stop_timer "SMT propagate (s)";
      aux reduction etat_smt next_bet period 1 []
    with
      | Smt.Conflit_smt _ 
      | Empty_clause _-> 
        stats#record "SMT conflicts";
        Unsolvable
      | Unsat -> Unsolvable

  let print_answer p = function
    | Unsolvable -> Printf.fprintf p "s UNSATISFIABLE\n"
    | Solvable (values, print_result) -> Printf.fprintf p "s SATISFIABLE\n%t%!" print_result


end
