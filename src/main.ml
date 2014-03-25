open Lexing
open Printf
open Debug
open Config
open Algo

let get_formule input = function
  | Cnf -> 
      let (n,cnf) = Cnf.parse input in 
      (None,n,cnf)
  | Tseitin ->
      let raw = Tseitin.parse input in
      let timer = stats#get_timer "Reduction (s)" in
      let (cnf,assoc) = Reduction.renommer (Tseitin.to_cnf raw)  (Tseitin.print_answer) in
      timer#stop;
      (Some assoc,assoc#max,cnf)
  | Color k -> 
      let raw = Color.parse input in
      let timer = stats#get_timer "Reduction (s)" in
      let (cnf,assoc) = Reduction.renommer (Color.to_cnf raw k) (Color.print_answer k raw) in
      timer#stop;
      (Some assoc,assoc#max,cnf)

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
  let (assoc,n,cnf) = get_formule (get_input()) config.problem_type in
  debug#p 1 "Using algorithm %s and heuristic %s" config.nom_algo config.nom_heuristic;
  begin
    match config.print_cnf with 
      | None -> ()
      | Some p -> 
          match assoc with
            | None -> print_cnf p (n,cnf)
            | Some assoc -> fprintf p "c RÃ©duction :\n%a\n%t%!" print_cnf (n,cnf) assoc#print_reduction
  end;
  let timer = stats#get_timer "Time (s)" in
  let answer = config.algo config.heuristic n cnf in
  timer#stop;
  printf "%a\n%!" print_answer (answer,assoc);
  debug#p 0 " Stats :\n%t%!" stats#print;
  Answer.check n cnf answer;
  exit 0

let _ = main()

















