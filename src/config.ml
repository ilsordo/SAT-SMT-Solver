open Debug
open Printf

type problem = Cnf | Color of int | Tseitin

type config = 
    { 
      mutable problem_type : problem;
      mutable print_cnf : bool;
      mutable input : string option; 
      mutable algo : int -> int list list -> Answer.answer; 
      mutable nom_algo : string 
    }

let config = 
  { 
    problem_type = Cnf;
    print_cnf = false;
    input = None;
    algo = Algo_dpll.algo;
    nom_algo = "dpll"
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
  
  let speclist = Arg.align [
    ("-algo",Arg.String parse_algo,"dpll|wl");
    ("-d",Arg.Int set_debug_level,"k Debug depth k");
    ("-b",Arg.Int set_blocking_level,"k Interaction depth k");
    ("-color",Arg.Int (fun k -> config.problem_type <- (Color k)),"k");
    ("-tseitin",Arg.Unit (fun () -> config.problem_type <- Tseitin),"");
    ("-print_cnf",Arg.Unit (fun () -> config.print_cnf <- true)," Prints reduction");
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
