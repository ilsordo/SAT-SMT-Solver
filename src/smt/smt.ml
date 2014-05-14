open Formula
open Clause
open Algo
open Smt_base

module Make_smt = functor(Algo : Algo_base) -> functor (Smt : Smt_base) ->
struct
  
  let algo (data : Smt.atom formula) period =
    
    (* Faire un pari, propager, se relever en cas de conflit *)
    let rec aux etat_smt next_bet period date acc =
      match next_bet () with
        | No_bet (backtrack) ->
            begin
              try
                let etat_smt = Smt.propagate acc etat_smt in
                  Solvable .......   (* On a fini *)
              with
                | Conflit_smt clause ->
                    let (undo_list,next_bet) = Algo.backtrack clause in
                    let etat_smt = Smt.backtrack undo_list etat_smt in
                    aux etat_smt next_bet period 0 []
            end
        | Bet_done (assignations,next_bet,backtrack) -> 
        (******************)
            let acc = (List.rev_append assignations acc) in (* pas sur pour le rev, pas besoin du append ? *)
            if date = period then (* c'est le moment de propager dans la théorie *)
              begin
                try
                  let etat_smt = Smt.propagate acc etat_smt in 
                    aux etat_smt next_bet period (date+1) []
                with
                  | Conflit_smt clause ->
                      let (undo_list,next_bet) = Algo.backtrack clause in
                      let etat_smt = Smt.backtrack undo_list etat_smt in
                      aux etat_smt next_bet period 0 []      
              end        
            else
              aux etat_smt next_bet period (date+1) acc
        | Conflit_dpll (undo_list,next_bet) -> (* renommer ce conflit ? *) (* je suppose ici que dpll a déjà backtracké dans son coin *)
            let etat_smt = Smt.backtrack undo_list etat_smt in
            aux etat_smt next_bet period 0 []  
        | Unsolvable -> Unsolvable          
        (******************)
     
    let (etat_smt,n,cnf) = Smt.init data in
    match algo n cnf with
      | Backtrack -> Unsolvable
      | Fine (prop_init, next_bet) ->
          try
            let etat_smt = Smt.propagate prop_init etat_smt in
            aux etat_smt next_bet period 1 []
          with
            | Conflit_smt _ -> Unsolvable


















