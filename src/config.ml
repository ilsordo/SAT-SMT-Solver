open Debug
open Printf

type problem = Cnf | Color of int | Tseitin

type config = 
    { 
      mutable problem_type : problem;
      mutable print_cnf : out_channel option;
      mutable input : string option; 
      mutable algo : Algo.t;
      mutable nom_algo : string;
      mutable heuristic : Heuristic.t;
      mutable nom_heuristic : string
    }

let config = 
  { 
    problem_type = Cnf;
    print_cnf = None;
    input = None;
    algo = Algo_dpll.algo;
    nom_algo = "dpll";
    heuristic = Heuristic.(next polarite_rand);
    nom_heuristic = "next_rand"
  }

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

  let parse_heuristic s =
    let heuristic = match s with
      | "next_rand" -> Heuristic.(next polarite_rand)
      | "next_mf" -> Heuristic.(next polarite_most_frequent)
      | "rand_rand" -> Heuristic.(rand polarite_rand)
      | "rand_mf" -> Heuristic.(rand polarite_most_frequent)
      | "moms" -> Heuristic.moms
      | "dlis" -> Heuristic.dlis
      | _ -> raise (Arg.Bad ("Unknown algorithm : "^s)) in
    config.heuristic <- heuristic;
    config.nom_heuristic <- s in
  let parse_output s =
    if s = "-" then
      config.print_cnf <- Some stdout
    else
      let out = try Some (open_out s)
        with Sys_error e -> eprintf "Error : %s" e; None in
      config.print_cnf <- out in
  
  let speclist = Arg.align [
    ("-algo",     Arg.String parse_algo,                              "dpll|wl");
    ("-h",        Arg.String parse_heuristic,                         " Heuristic");
    ("-d",        Arg.Int debug#set_debug_level,                            "k Debug depth k");
    ("-b",        Arg.Int debug#set_blocking_level,                         "k Interaction depth k");
    ("-color",    Arg.Int (fun k -> config.problem_type <- (Color k)),"k");
    ("-tseitin",  Arg.Unit (fun () -> config.problem_type <- Tseitin),"");
    ("-print_cnf",Arg.String parse_output,                            "[f|-] Prints reduction to f (- = stdout");
  ] in
  
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
