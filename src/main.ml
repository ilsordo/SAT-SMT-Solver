open Lexing
open Printf
open Debug
open Config
open Algo_base
open Smt
open Smt_base
open Algo_parametric

let print_cnf p (n,f) = 
  fprintf p "p cnf %d %d\n" n (List.length f);
  List.iter (fun c -> List.iter (fun (b,v) -> fprintf p "%s%d " (if b then "" else "-") v) c; fprintf p "0\n") f 

let run (algo : Algo.t) assoc n cnf =
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
  Answer.check n cnf answer; (* Tout résultat positif est vérifié *)
  answer
  

let main () =
  parse_args(); (* Initialise config *)
  let module Base_algo = ( val config.algo : Algo_base ) in (* config.algo est un module de première classe *)
  debug#p 1 "Using algorithm %s and heuristic %s %s" Base_algo.name config.nom_heuristic (if config.clause_learning then "with clause learning" else "");
  let input = Config.get_input() in 
  begin
    match config.problem_type with
      | Cnf ->
          begin
            let (n,cnf) = Cnf.parse input in 
            let module A = Algo.Bind( Base_algo ) in
            printf "%a%!" Cnf.print_answer (run A.algo None n cnf)
          end      

      | Color k -> 
          let raw = Color.parse input in
          let module Reduction = Reduction.Reduction ( struct type t = string let print_value p s = fprintf p "%s" s end ) in
          stats#start_timer "Reduction (s)";
          let (cnf,assoc) = Reduction.renommer (Color.to_cnf raw k) in
          stats#stop_timer "Reduction (s)";
          let module A = Algo.Bind( Base_algo ) in
          printf "%a%!" (Color.print_answer k raw assoc) (run A.algo (Some assoc) assoc#max cnf)

      | Smt s ->
          let module Base_smt = ( val s : Smt_base ) in
          let module Smt = Make_smt ( Algo_parametric.Bind ( Base_algo ) ) ( Base_smt ) in
          try
            stats#start_timer "Reduction (s)";
            let (cnf,assoc) = Smt.reduce (Smt.parse input) in
            stats#stop_timer "Reduction (s)";
            printf "%a\n%!" Smt.print_answer (run (Smt.algo config.smt_period assoc) (Some assoc) (assoc#max) cnf)
          with
            | Formula_tree.Illegal_variable_name s ->
                eprintf "Illegal variable name : %s\n%!" s;
                exit 1
  end;
  debug#p 0 " Stats :\n%t%!" stats#print;
  exit 0

let _ = 
  try
    Printexc.record_backtrace true;
    main()
  with
      Stack_overflow -> 
        Printexc.print_backtrace stderr; 
        flush stderr; 
        raise Stack_overflow (* En cas de panique *)




















