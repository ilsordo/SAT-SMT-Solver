open Lexing
open Printf
open Debug
open Config
open Algo_base
open Smt

let init input = function
 
let print_cnf p (n,f) = 
  fprintf p "p cnf %d %d\n" n (List.length f);
  List.iter (fun c -> List.iter (fprintf p "%d ") c; fprintf p "0\n") f 

let print_answer p (answer,assoc) =
  match assoc with
    | None ->
        Answer.print_answer p answer
    | Some reduction ->
        reduction#print_answer p answer

let run algo n cnf =
  begin
    match config.print_cnf with 
      | None -> ()
      | Some p -> 
          match assoc with
            | None -> print_cnf p (n,cnf)
            | Some assoc -> fprintf p "c Réduction :\n%a\n%t%!" print_cnf (n,cnf) assoc#print_reduction
  end;
  stats#start_timer "Total execution (s)";
  let answer = algo config.heuristic config.clause_learning config.interaction n cnf in
  stats#stop_timer "Total execution (s)";
  Answer.check n cnf answer
  

let main () =
  parse_args();
  let module Base_algo = ( config.algo : Algo_base ) in
  debug#p 1 "Using algorithm %s and heuristic %s %s" Base_algo.name config.nom_heuristic (if config.clause_learning then "with clause learning" else "");
  let input = Config.get_input() in
  begin
    match config.problem_type with
      | Cnf ->
          let (n,cnf) = Cnf.parse input in 
          let module A = Algo.Bind( Base_algo ) in
          match run A.algo n cnf with
            | Unsolvable ->
            | Color k -> 
                let raw = Color.parse input in
                stats#start_timer "Reduction (s)";
                let (cnf,assoc) = Reduction.renommer (Color.to_cnf raw k) (Color.print_answer k raw) in
                stats#stop_timer "Reduction (s)";
                let module A = Algo.Bind( Base_algo ) in
                (A.algo,Some assoc,assoc#max,cnf)
            | Smt s ->
                let module Base_smt = ( s : Smt_base ) in
                let module Smt = Make_smt ( Base_smt ) in
                try
                  let (cnf,assoc) = Smt.reduce (Smt.parse input) in
                  a
                with
                  | Formula_tree.Illegal_variable_name s ->
                      eprintf "Illegal variable name : %s\n%!" s;
                      exit 1
  end
    
    debug#p 0 " Stats :\n%t%!" stats#print;
  exit 0

let _ = 
  try
    Printexc.record_backtrace true;
    main()
  with
      Stack_overflow -> Printexc.print_backtrace stderr; flush stderr; raise Stack_overflow




















