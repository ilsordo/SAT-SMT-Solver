open Dpll
open Lexing
open Printf
open Formule
open Debug

let usage () =
  eprintf "Usage:\n resol [fichier]\n%!";
  exit 1

let parse input =
  try
    let lex = Lexing.from_channel input in
    let (n,f) = Parser.main Lexer.token lex in
    (n,f)
  with
    | _ -> 
        eprintf "Input error\n%!";
        exit 1

let get_input () =
  match Array.length Sys.argv with
    | 1 -> stdin
    | 2 -> 
        begin
          try
            open_in Sys.argv.(1)
          with
            | Sys_error e -> 
                eprintf "Impossible de lire %s:%s\n%!" Sys.argv.(1) e;
                exit 1
        end
    | _ -> usage()
     
let main () =
  set_debug_level 3;
  set_blocking_level 0;
  let (n,cnf) = parse (get_input ()) in
  let f = new formule_dpll in
  f#init n cnf;
  let answer = dpll f in
  printf "%a\n%t%!" print_answer answer print_stats;
  begin
    match answer with
      | Unsolvable -> ()
      | Solvable valeurs ->
          let f_verif = new formule in
          f_verif#init n cnf;
          valeurs#iter (fun v b -> f_verif#set_val b v);
          printf "Check : %B\n%!" f#eval
  end;
  exit 0

let _ = main()

















