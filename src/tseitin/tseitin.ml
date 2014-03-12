(*
module Association = Map.Make(String)
*)

open Renommage


type tseitin_formule =
  | Var of string
  | And of tseitin_formule*tseitin_formule (* et *)
  | Or of tseitin_formule*tseitin_formule  (* ou *)
  | Imp of tseitin_formule*tseitin_formule (* implication *)
  | Equ of tseitin_formule*tseitin_formule (* on gère même l'équivalence ! *)
  | Not of tseitin_formule                 (* négation *)
  
  
(*   
let makefresh () =
  let n = ref 0 in
  fun () -> incr n; string_of_int !n

let mfresh=makefresh() (* génère des variables fraiches *)

*)

let to_cnf t_formule = (* construit la cnf, en utilisant des variables fraiches *)
  let rec aux t_f = match t_f with
    | Var v -> ((true,v),[])
    | Not f -> let ((b,v),g)=aux f in
                ((not b,v),g)
    | And(f,g) -> let ((b1,v1),h1)=aux f in
                  let ((b2,v2),h2)=aux g in
                  let fresh="_"^(mfresh()) in
                    ((true,fresh),List.rev_append h1 (List.rev_append h2 [[(not b1,v1);(not b2,v2);(true,fresh)];[(false,fresh);(b1,v1)];[(false,fresh);(b2,v2)]])) 
    | Or(f,g) -> let ((b1,v1),h1)=aux f in
                 let ((b2,v2),h2)=aux g in
                 let fresh="_"^mfresh() in
                   ((true,fresh),List.rev_append h1 (List.rev_append h2 [[(not b1,v1);(true,fresh)];[(not b2,v2);(true,fresh)];[(false,fresh);(b1,v1);(b2,v2)]])) 
    | Imp(f,g) -> let ((b1,v1),h1)=aux f in
                  let ((b2,v2),h2)=aux g in
                  let fresh="_"^mfresh() in
                    ((true,fresh),List.rev_append h1 (List.rev_append h2 [[(b1,v1);(true,fresh)];[(not b2,v2);(true,fresh)];[(false,fresh);(not b1,v1);(b2,v2)]]))
    | Equ(f,g) -> aux (And(Imp(f,g),Imp(g,f)))
                  (* let ((b1,v1),h1)=aux f in
                  let ((b2,v2),h2)=aux g in
                  let fresh="_"^(mfresh()) in
                    ((true,fresh),List.rev_append h1 (List.rev_append h2 [[(false,fresh);(not b1,v1);(b2,v2)];[(false,fresh);(b1,v1);(not b2,v2)];[(true,fresh);(b1,v1);(b2,v2)];[(true,fresh);(b1,v1);(b2,v2)]])) *)
  in let (p,f)=aux t_formule in
    ([p]::f)
      
      
(* 
let convert_clause c assoc = (* remplace les noms des variables dans la clause c, d'après la table d'association assoc *)
  let rec aux c res = match c with
		  | [] -> res
		  | (b,v)::q -> if b then aux q ((Association.find v assoc)::res) else aux q ((-(Association.find v assoc))::res) 
  in aux c []

let convert_formule f assoc = (* remplace les noms des variables dans la formule f, d'après la table d'association assoc *)
  let rec aux f res = match f with
		  | [] -> res
		  | t::q -> aux q ((convert_clause t assoc)::res)
  in aux f []

		  
		  		                   
let tseitin formule = (* renvoie formule original + CNF + table d'association. Pour ce restreindre aux vars de départ, on ne regardera pas les _ dans la table *)
  let t_formule = formule_to_cnf formule in
    let m=ref 1 in (* associe à chaque variable (string) un nombre unique. Permet d'avoir le format DIMACS *)
    let assoc=ref Association.empty in
  		List.iter 
		  (fun l -> List.iter 
		              (fun (b,s) -> if (not (Association.mem s !assoc)) then 
		                              (assoc:=(Association.add s !m !assoc); incr m)
		               ) l
		  ) t_formule;
  (t_formule,convert_formule t_formule !assoc,!assoc)
*)		  
		  
		  
		  
		  
		  
		  
		  
		  
		  
		  
		  
		  
		  
				  
type config = { mutable input : string option; mutable algo : int -> int list list -> answer; mutable affichage : bool ; mutable nom_algo : string }

let config = { input = None; algo = Algo_dpll.algo; affichage = false ; nom_algo = "dpll" }

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
  let set_affichage = 
    config.affichage <- true in
  let speclist = Arg.align [
    ("-algo",Arg.String parse_algo,"dpll|wl");
    ("-cnf",Arg.Unit set_affichage,"Afficher la cnf équivalente")] in
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
    TseitinParser.main TseitinLexer.token lexbuf
  with
    | _ -> 
        eprintf "Input error\n%!";
        exit 1

let _ =
  parse_args();
  let t_formule= parse (get_input ()) in
  let (formule,assoc)=renommer t_formule in
  let answer = config.algo (Renommage.cardinal assoc) cnf in
  begin
    match answer with
      | Unsolvable -> 
          print_string "s UNSATISFIABLE\n"
      | Solvable valeurs ->
          print_string "s SATISFIABLE\n";
          Renommage.iter
            (fun var ren -> 
               if (var.(0) <> '_') then 
                 match valeurs#find var with
                  | None -> assert false
                  | Some b -> if b then (print_string "v "^var) else (print_string "f "^var))
            assoc
  end;
  exit 0









