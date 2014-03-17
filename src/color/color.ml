open Renommage
open Answer
open Printf

(*** attention : multicoloration d'un sommet possible *)

type t = (int*int*((int*int) list))

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
  
(*
let print_sommet values p name id =
  if name <> "" && name.[0] <> '_' && values#find id = Some true then
    let l = String.length name in
    let cut = String.index name '_' in
    Printf.fprintf p "%s colorié en %s\n" (String.sub name 0 cut) (String.sub name (cut+1) (l-cut-1))

(* Format de sortie ? *)
let print_answer p k assoc = function
  | Unsolvable -> fprintf p "s Pas de coloriage à %d couleurs\n" k
  | Solvable values ->
      fprintf p "s Coloriable en %d couleurs\n" k;
      assoc#iter (print_sommet values p)
*)      
      
(* Fonctions d'affichage de la sortie *)

let print_aretes p cnf assoc = (***)
  let rec aux l = match l with
    | [] -> ()
    | [v1;v2]::q -> 
        begin
         if (v1<0) then
           match assoc#get_name (-v1) with
             | None -> assert false
             | Some s1 ->
                 let l1 = String.length s1 in
                 let cut1 = String.index s1 '_' in
                   if ((String.sub s1 (cut1+1) (l1-cut1-1))="1") then 
                     begin 
                       match assoc#get_name (-v2) with
                         | None -> assert false
                         | Some s2 -> 
                             let cut2 = String.index s2 '_' in
                               Printf.fprintf p "\"%s\" -- \"%s\" \n" (String.sub s1 0 cut1) (String.sub s2 0 cut2)
                      end
        end;
        aux q
    | t::q -> aux q
  in aux cnf
    
                         
let print_sommet values p couleurs name id =
  if name <> "" && name.[0] <> '_' && values#find id = Some true then
    let l = String.length name in
    let cut = String.index name '_' in
    Printf.fprintf p "\"%s\" [shape=circle, style=filled, fillcolor=\"%s\"]\n" (String.sub name 0 cut) (couleurs.((int_of_string (String.sub name (cut+1) (l-cut-1)))-1))
    
          
let print_answer p k assoc cnf = function (***)
  | Unsolvable -> fprintf p "s Pas de coloriage à %d couleurs\n" k
  | Solvable values ->
      begin
        Random.self_init();
        let couleurs = Array.make k "" in 
          for i=0 to k-1 do
            couleurs.(i) <- ((string_of_float (Random.float 1.0))^","^(string_of_float (Random.float 1.0))^","^(string_of_float (Random.float 1.0)))
          done;
        fprintf p "graph {\n";
        print_aretes p cnf assoc; (***)
        assoc#iter (print_sommet values p couleurs);
        fprintf p "}\n"
     end    
      
