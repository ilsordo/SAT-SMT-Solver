open Lexing
open Printf
open Debug
open Config
open Algo

let get_formule input = function
  | Cnf -> 
      let (n,cnf) = Cnf.parse input in 
      (None,n,cnf)
  | Color k -> 
      let raw = Color.parse input in
      stats#start_timer "Reduction (s)";
      let (cnf,assoc) = Reduction.renommer (Color.to_cnf raw k) (Color.print_answer k raw) in
      stats#stop_timer "Reduction (s)";
      (Some assoc,assoc#max,cnf)
  | Smt s ->
     

let print_cnf p (n,f) = 
  fprintf p "p cnf %d %d\n" n (List.length f);
  List.iter (fun c -> List.iter (fprintf p "%d ") c; fprintf p "0\n") f 

let print_answer p (answer,assoc) =
  match assoc with
    | None ->
        Answer.print_answer p answer
    | Some reduction ->
        reduction#print_answer p answer

let main () =
  parse_args();
  let module Base_algo = ( config.algo : Algo_base ) in
  debug#p 1 "Using algorithm %s and heuristic %s %s" Base_algo.name config.nom_heuristic (if config.clause_learning then "with clause learning" else "");
  let (assoc,n,cnf) = get_formule (get_input()) config.problem_type in
  begin
    match config.print_cnf with 
      | None -> ()
      | Some p -> 
          match assoc with
            | None -> print_cnf p (n,cnf)
            | Some assoc -> fprintf p "c Réduction :\n%a\n%t%!" print_cnf (n,cnf) assoc#print_reduction
  end;
  stats#start_timer "Total execution (s)";
  let answer = config.algo config.heuristic config.clause_learning config.interaction n cnf in
  stats#stop_timer "Total execution (s)";
  printf "%a\n%!" print_answer (answer,assoc);
  debug#p 0 " Stats :\n%t%!" stats#print;
  Answer.check n cnf answer;
  exit 0

let _ = 
  try
    Printexc.record_backtrace true;
    main()
  with
      Stack_overflow -> Printexc.print_backtrace stderr; flush stderr; raise Stack_overflow




















