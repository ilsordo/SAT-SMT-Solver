open Debug
open Printf
open Algo
open Algo_base
open Smt_base
open Smt

module Dpll = Bind(Algo_dpll)
module Wl = Bind(Algo_wl)

type problem = Cnf | Color of int | Smt of ( module Smt_base )

type config = 
    { 
      mutable problem_type : problem;
      mutable print_cnf : out_channel option;
      mutable input : string option; 
      mutable algo : (module Algo_base);
      mutable heuristic : Heuristic.t;
      mutable nom_heuristic : string;
      mutable clause_learning : bool;
      mutable interaction : bool;
      mutable smt_period : int
    }

let config = 
  { 
    problem_type = Cnf;
    print_cnf = None;
    input = None;
    algo = ( module Algo_dpll : Algo_base );
    heuristic = Heuristic.(next polarite_next);
    nom_heuristic = "next_next";
    clause_learning = false;
    interaction = false;
    smt_period = 0
  }

(* Utilise le module Arg pour modifier l'environnement config *)
let parse_args () =
  let use_msg = "Usage:\n resol [file.cnf] [options]\n" in
  
  let parse_algo s =
    let algo = match s with
      | "dpll" -> ( module Algo_dpll : Algo_base )
      | "wl" -> ( module Algo_wl : Algo_base )
      | _ -> raise (Arg.Bad ("Unknown algorithm : "^s)) in
    config.algo <- algo in

  let parse_heuristic s =
    let heuristic = match s with
      | "next_next" -> Heuristic.(next polarite_next)
      | "next_rand" -> Heuristic.(next polarite_rand)
      | "next_mf" -> Heuristic.(next polarite_most_frequent)
      | "rand_rand" -> Heuristic.(rand polarite_rand)
      | "rand_mf" -> Heuristic.(rand polarite_most_frequent)
      | "moms" -> Heuristic.moms
      | "dlis" -> Heuristic.dlis
      | "jewa" -> Heuristic.jewa
      | "dlcs" -> Heuristic.(dlcs polarite_most_frequent)
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
    ("-algo",     Arg.String parse_algo,                                                      "[dpll|wl] Algorithm");
    ("-h",        Arg.String parse_heuristic,                                                 "[next_rand|...] Heuristic");
    ("-cl",       Arg.Unit (fun () -> config.clause_learning <- true),                        " Clause learning");
    ("-d",        Arg.Int debug#set_debug_level,                                              "k Debug depth k");
    ("-b",        Arg.Int debug#set_blocking_level,                                           "k Interaction depth k");
    ("-color",    Arg.Int (fun k -> config.problem_type <- (Color k)),                        "k Color solver");
    (*("-tseitin",  Arg.Unit (fun () -> config.problem_type <- Smt (module Tseitin : Smt_base)),           " Tseitin solver");*)
    ("-print_cnf",Arg.String parse_output,                                                    "[f|-] Prints reduction to f (- = stdout)");
    ("-i",        Arg.Unit (fun () -> config.interaction <- true),                            " Interaction");
    ("-p",        Arg.Int (fun n -> config.smt_period <- n ),                                  "n Smt update period");
    ("-diff",     Arg.Unit (fun () -> config.problem_type <- Smt (module Difference_logic : Smt_base)),  " Difference logic")
    ("-cc",       Arg.Unit (fun () -> config.problem_type <- Smt (module Congruence_closure : Smt_base)),  " Congruence closure");
    ("-eq",       Arg.Unit (fun () -> config.problem_type <- Smt (module Equality : Smt_base)),  " Equality")
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




