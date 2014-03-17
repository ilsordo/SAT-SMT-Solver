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
      let (cnf,assoc) = Renommage.renommer (Tseitin.to_cnf (Tseitin.parse input)) in
      (Some assoc,assoc#max,cnf)
  | Color k -> 
      let (cnf,assoc) = Renommage.renommer (Color.to_cnf (Color.parse input) k) in
      (Some assoc,assoc#max,cnf)

let print_cnf p (n,f) = 
  fprintf p "p cnf %d %d\n" n (List.length f);
  List.iter (fun c -> List.iter (fprintf p "%d ") c; fprintf p "0\n") f 

let print_answer p (answer,assoc,cnf,problem) = (***)
  match problem with
    | Cnf ->
        Answer.print_answer p answer
    | Tseitin ->
        let assoc = match assoc with Some x -> x | None -> assert false in
        Tseitin.print_answer p assoc answer
    | Color k ->
        let assoc = match assoc with Some x -> x | None -> assert false in
        Color.print_answer p k assoc cnf answer (***)


let main () =
  parse_args();
  let (assoc,n,cnf) = get_formule (get_input()) config.problem_type in
  debug 1 "Using algorithm %s" config.nom_algo;
  if config.print_cnf then debug 1 "Reduction :\n%a\n%!" print_cnf (n,cnf);
  let answer = config.algo n cnf in
  printf "%a\n%!" print_answer (answer,assoc,cnf,config.problem_type); (***)
  debug 1 "Stats :\n%t%!" print_stats;
  check n cnf answer;
  exit 0

let _ = main()

















