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
  begin
    match config.print_cnf with 
      | None -> ()
      | Some p -> 
          match assoc with
            | None -> print_cnf p (n,cnf)
            | Some assoc -> fprintf p "c Reduction\n%a\n\n%t%!" print_cnf (n,cnf) assoc#print_reduction
  end;
  let answer = config.algo n cnf in
  printf "%a\n%!" print_answer (answer,assoc);
  debug 1 "Stats :\n%t%!" print_stats;
  check n cnf answer;
  exit 0

let _ = main()

















