open Reduction
open TseitinFormule
open Answer
open Printf

type t = TseitinFormule.t


let rec print_formule p = function
  | Var v -> Printf.fprintf p "%s" v
  | Not f -> Printf.fprintf p "Not(%a)" print_formule f
  | And(f,g) -> Printf.fprintf p "(%a)/\\(%a)" print_formule f print_formule g
  | Or(f,g) -> Printf.fprintf p "(%a)\\/(%a)" print_formule f print_formule g
  | Imp(f,g) -> Printf.fprintf p "(%a)->(%a)" print_formule f print_formule g
  | Equ(f,g) -> Printf.fprintf p "(%a)<->(%a)" print_formule f print_formule g


let to_cnf t_formule = (* construit la cnf, en utilisant des variables fraiches *)
  let fresh = new counter 0 string_of_int in (* générateur de variables fraiches successives *)
  let rec aux cnf = function
    | Var v ::q -> aux((true,v),cnf)
    | Not f ::q -> 
        let ((b,v),g) = aux cnf f in
        ((not b,v),g)
    | And(f,g) -> 
        let ((b1,v1),h1) = aux cnf f in
        let ((b2,v2),h2) = aux h1 g in
        let fresh = "_"^fresh#next in
        ((true,fresh), 
         [(not b1,v1);(not b2,v2);(true,fresh)]
         ::[(false,fresh);(b1,v1)]
         ::[(false,fresh);(b2,v2)]
         ::h2
        )
    | Or(f,g) -> 
        let ((b1,v1),h1) = aux cnf f in
        let ((b2,v2),h2) = aux h1 g in
        let fresh="_"^fresh#next in
        ((true,fresh),
         [(not b1,v1);(true,fresh)]
         ::[(not b2,v2);(true,fresh)]
         ::[(false,fresh);(b1,v1);(b2,v2)]
         ::h2
        ) 
    | Imp(f,g) -> 
        let ((b1,v1),h1) = aux cnf f in
        let ((b2,v2),h2) = aux h1 g in
        let fresh="_"^fresh#next in
        ((true,fresh),
         [(b1,v1);(true,fresh)]
         ::[(not b2,v2);(true,fresh)]
         ::[(false,fresh);(not b1,v1);(b2,v2)]
         ::h2
        )
    | Equ(f,g) -> aux cnf (And(Imp(f,g),Imp(g,f)))
  in let (p,f) = aux [] t_formule in
     ([p]::f)

(* Récupération de l'entrée *)

let parse input =
  try
    let lex = Lexing.from_channel input in
    TseitinParser.main TseitinLexer.token lex
  with
    | _ -> 
        Printf.eprintf "Input error\n%!";
        exit 1


(* Affichage de la sortie *)

let print_var values p name id =
  if name <> "" && name.[0] <> '_' then
    let s = if values#find id = Some true then "" else "-" in
    Printf.fprintf p "v %s%s\n" s name

let print_answer assoc p = function
  | Unsolvable -> fprintf p "s UNSATISFIABLE\n"
  | Solvable values ->
      fprintf p "s SATISFIABLE\n";
      assoc#iter (print_var values p)










