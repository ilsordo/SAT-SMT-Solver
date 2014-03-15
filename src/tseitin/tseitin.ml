open Renommage
open TseitinFormule
open Answer
open Printf

type t = TseitinFormule.t

let to_cnf t_formule = (* construit la cnf, en utilisant des variables fraiches *)
  let fresh = new counter 0 string_of_int in
  let rec aux = function
    | Var v -> ((true,v),[])
    | Not f -> 
        let ((b,v),g) = aux f in
        ((not b,v),g)
    | And(f,g) -> 
        let ((b1,v1),h1)=aux f in
        let ((b2,v2),h2)=aux g in
        let fresh = "_"^fresh#next in
        ((true,fresh),List.rev_append h1 (List.rev_append h2 [[(not b1,v1);(not b2,v2);(true,fresh)];[(false,fresh);(b1,v1)];[(false,fresh);(b2,v2)]])) 
    | Or(f,g) -> 
        let ((b1,v1),h1)=aux f in
        let ((b2,v2),h2)=aux g in
        let fresh="_"^fresh#next in
        ((true,fresh),List.rev_append h1 (List.rev_append h2 [[(not b1,v1);(true,fresh)];[(not b2,v2);(true,fresh)];[(false,fresh);(b1,v1);(b2,v2)]])) 
    | Imp(f,g) -> 
        let ((b1,v1),h1)=aux f in
        let ((b2,v2),h2)=aux g in
        let fresh="_"^fresh#next in
        ((true,fresh),List.rev_append h1 (List.rev_append h2 [[(b1,v1);(true,fresh)];[(not b2,v2);(true,fresh)];[(false,fresh);(not b1,v1);(b2,v2)]]))
    | Equ(f,g) -> aux (And(Imp(f,g),Imp(g,f)))
  in let (p,f) = aux t_formule in
     ([p]::f)
    

let parse input =
  try
    let lex = Lexing.from_channel input in
    TseitinParser.main TseitinLexer.token lex
  with
    | _ -> 
        Printf.eprintf "Input error\n%!";
        exit 1

let print_var values p name id =
  if name <> "" && name.[0] <> '_' then
    let s = if values#find id = Some true then "" else "-" in
    Printf.fprintf p "v %s%s\n" s name

let print_answer p assoc = function
  | Unsolvable -> fprintf p "s UNSATISFIABLE\n"
  | Solvable values ->
      fprintf p "s SATISFIABLE\n";
      assoc#iter (print_var values p)










