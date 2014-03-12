open Answer
open Lexing
open Printf
open Formule
open Debug

type config = { mutable input : string option; mutable algo : int -> int list list -> answer; mutable nom_algo : string }

let config = { input = None; algo = Algo_dpll.algo; nom_algo = "dpll" }

(* Utilise le module Arg pour modifier l'environnement config *)
let parse_args () =
  let use_msg = "Usage:\n resol [file.cnf] [options]\n" in
  let parse_algo s =
    let algo = match s with
      | "dpll" -> Algo_dpll.algo
      | "wl" -> Algo_wl.algo 
      | _ -> raise (Arg.Bad ("Unknown algorithm : "^s)) in
    config.algo <- algo;
    config.nom_algo <- s in
  let speclist = Arg.align [
    ("-algo",Arg.String parse_algo,"dpll|wl");
    ("-d",Arg.Int set_debug_level,"k Debug depth k");
    ("-b",Arg.Int set_blocking_level,"k Interaction depth k")] in
  Arg.parse speclist (fun s -> config.input <- Some s) use_msg
    
let get_input () =
  match config.input with
    | None -> stdin
    | Some f-> 
        try
          open_in f
        with
          | Sys_error e -> 
              eprintf "Impossible de lire %s:%s\n%!" Sys.argv.(1) e;
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

let main () =
  parse_args();
  let (n,cnf) = parse (get_input ()) in
  debug 1 "Using algorithm %s" config.nom_algo;
  let answer = config.algo n cnf in
  printf "%a\n%!" print_answer answer;
  debug 1 "Stats :\n%t%!" print_stats;
  begin
    match answer with
      | Unsolvable -> ()
      | Solvable valeurs ->
          let f_verif = new formule in
          f_verif#init n cnf;
          valeurs#iter (fun v b -> f_verif#set_val b v);
          debug 1 "Check : %B\n%!" f_verif#eval
  end;
  exit 0

let _ = main()

















