open Reduction
open TseitinFormule
open Formula
open Answer
open Printf

type t = TseitinFormule.t

let rec print_formule p = function
  | Atom v -> Printf.fprintf p "%s" v
  | Not f -> Printf.fprintf p "Not(%a)" print_formule f
  | And(f,g) -> Printf.fprintf p "(%a)/\\(%a)" print_formule f print_formule g
  | Or(f,g) -> Printf.fprintf p "(%a)\\/(%a)" print_formule f print_formule g
  | Imp(f,g) -> Printf.fprintf p "(%a)->(%a)" print_formule f print_formule g
  | Equ(f,g) -> Printf.fprintf p "(%a)<->(%a)" print_formule f print_formule g


let to_cnf t_formule = (* construit la cnf, en utilisant des variables fraiches *)
  let fresh = new counter 1 (fun i -> "_"^(string_of_int i)) in (* générateur de variables fraiches successives *)
  let impl x1 x2 = [(false,x1);(true,x2)] in (* Raccourci *)
  let rec aux cnf = function (* le label peut être imposé par un connecteur ou laissé au choix *)
    | [] -> cnf
    | (f, label)::q ->
        let cnf, formule = match f with
          | Atom v ->
              ((impl label v)::(impl v label)::cnf), q
          | Not f ->
              let l1 = fresh#next in
              ([(false,label);(false,l1)]::[(true,label);(true,l1)]::cnf), ((f,l1)::q)
          | And(f,g) ->
              let l1 = fresh#next in
              let l2 = fresh#next in
              ([(true,label);(false,l1);(false,l2)]::(impl label l1)::(impl label l2)::cnf), ((f,l1)::(g,l2)::q)
          | Or(f,g) ->
              let l1 = fresh#next in
              let l2 = fresh#next in
              ([(false,label);(true,l1);(true,l2)]::(impl l1 label)::(impl l2 label)::cnf), ((f,l1)::(g,l2)::q)
          | Imp(f,g) ->
              cnf, ((Or(Not f, g), label)::q)
          | Equ(f,g) -> 
              cnf, (((And(Imp(f,g),Imp(g,f))), label)::q) in
        aux cnf formule in
  let label = fresh#next in
  let res = [true,label]::(aux [] [t_formule, label]) in
  res
    

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










