open Reduction
open TseitinFormule
open Formula
open Answer
open Printf

type t = TseitinFormule.t    

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










