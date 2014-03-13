
open Renommage

(*** attention : multicoloration d'un sommet possible *)
(*** optimiser la fusion : travailler sur une seule liste qu'on fait grossir *)

let vertex_constraint i k = (* produit une clause (i_1,i_2...i_k) indiquant que le sommet i doit prendre 1 couleur parmi k *)
  let rec aux j res = 
    if j=0 then
      res
    else
      aux (j-1) ((true,(string_of_int i)^"_"^(string_of_int j))::res)
  in aux k []
  
let vertices_constraint n k = (* produit une _fomule_ (CNF) indiquant que chaque sommet entre 1 et n doit être colorié *)
  let rec aux i res=
    if i=0 then
      res
    else aux (i-1) ((vertex_constraint i k)::res)
  in aux n []  
  
  
let edge_constraint i j k cnf = (* produit une _formule_ (CNF) indiquant que les sommets i et j ne doivent pas partager une même couleur parmi les k possibles, et l'ajoute à la cnf déjà traitée cnf *)
  let rec aux l res = 
    if l=0 then
      res
    else
      aux (l-1) ([(false,(string_of_int i)^"_"^(string_of_int l));(false,(string_of_int j)^"_"^(string_of_int l))]::res)
  in aux k cnf

  
let to_cnf c_formule k = (* construit la cnf indiquant la coloration, utilise des variables fraiches *)
  let (v,e,c_f) = c_formule in
  let rec aux l res = match l with
    | [] -> res
    | (v1,v2)::q -> aux q (edge_constraint v1 v2 k res)
  in aux c_f (vertices_constraint v k)
  
  
      
let parse input =
  try
    let lex = Lexing.from_channel input in
    ColorParser.main ColorLexer.token lex
  with
    | _ -> 
        Printf.eprintf "Input error\n%!";
        exit 1
  
