open Answer
open Lexing
open Printf
open Debug
open Config

let get_formule input = function
  | Cnf -> 
      let (n,cnf) = Cnf.parse input in 
      (None,n,cnf)
  | Tseitin -> 
      let (cnf,assoc) = Reduction.renommer (Tseitin.to_cnf (Tseitin.parse input))  (Tseitin.print_answer) in
      (Some assoc,assoc#max,cnf)
  | Color k -> 
      let raw = Color.parse input in
      let (cnf,assoc) = Reduction.renommer (Color.to_cnf raw k) (Color.print_answer k raw) in
      (Some assoc,assoc#max,cnf)

let print_cnf p (n,f) = 
  fprintf p "p cnf %d %d\n" n (List.length f);
  List.iter (fun c -> List.iter (fprintf p "%d ") c; fprintf p "0\n") f 

let print_answer p (answer,assoc) = (***)
  match assoc with
    | None ->
        Answer.print_answer p answer
    | Some reduction ->
        reduction#print_answer p answer

let main () =
  parse_args();
  let (assoc,n,cnf) = get_formule (get_input()) config.problem_type in
  debug 1 "Using algorithm %s" config.nom_algo;
  if config.print_cnf then debug 1 "Reduction :\n%a\n%!" print_cnf (n,cnf);
  let answer = config.algo n cnf in
  printf "%a\n%!" print_answer (answer,assoc);
  debug 1 "Stats :\n%t%!" print_stats;
  check n cnf answer;
  exit 0

let _ = main()

















