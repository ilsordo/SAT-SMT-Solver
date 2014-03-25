open Sys
open Printf

let shuffle tab l = (* calcule les l premiers termes d'une permutation aléatoire du tableau tab *)
  let n = Array.length tab in
  for i = 0 to l-1 do
      let x = Random.int (n - i) + i in
      let v = tab.(x) in
      tab.(x) <- tab.(i);
      tab.(i) <- v
  done
    
let make_tab k = Array.init k (fun x -> x + 1) (* initialise un tableau de valeurs *)

let print_tab l p tab = (* construit des littéraux à partir d'un tableau de valeurs, en choisissant aléatoirement les positivités *)
  for i = 0 to l-1 do
    let s = if Random.bool() then "" else "-" in
    fprintf p "%s%d " s tab.(i)
  done

let gen_formule n l k p = (* génère une formule aléatoire de n variables et k clauses de longueur l chacune *)
  let tab = (make_tab n) in
  for i = 1 to k do
    shuffle tab l;
    fprintf p "%a0\n" (print_tab l) tab
  done

let _ =
  Random.self_init();
  let t = Sys.argv in
  try
    if Array.length t = 4 then
      let (n,l,k) = (int_of_string t.(1),int_of_string t.(2),int_of_string t.(3)) in
      if (l<=n) then
        printf "p cnf %d %d\n%t%!" n k (gen_formule n l k)
      else
        eprintf "Error : la taille des clauses est supérieure au nombre de variables (l>n)\n%!"
    else raise (Failure "")
  with Failure _ -> eprintf "Usage : gen n l k\n%!"


 
(*** Générateur de tseitin *)
(*
let random_connecteur = function 
    | 0 -> "~"
    | 1 -> "\\/" 
    | 2 -> "/\\"
    | 3 -> "=>"        
    | 4 -> "<=>"  
    | _ -> assert false      
    
let rec random_formula n c = (* génère une formule aléatoire de c connecteurs et n variables *)
  match random_connecteur (Random.int 5) with
    | "~" -> 
        if c=0 then
          "~"^"a"^(string_of_int (Random.int n))
        else 
          "~("^(random_formula n (c-1))^")"
    | s ->
        if c=0 then
          "a"^(string_of_int (Random.int n))^s^"a"^(string_of_int (Random.int n))
        else 
          "("^(random_formula n ((c-1)/2))^")"^s^"("^(random_formula n (c-1-(c-1)/2))^")"    

let _ = 
  Random.self_init();
  let t = Sys.argv in
  try
    if Array.length t = 3 then
      let (n,c) = (int_of_string t.(1),int_of_string t.(2)) in
       printf "%s\n" (random_formula n c)
    else raise (Failure "")
  with Failure _ -> eprintf "Usage : gen n c\n%!"
*)  


(*** Générateur de graphes *)
(*    
let random_edges n p pp = (* génère un graphe aléatoire de n sommets, avec proba p pour chaque arête *)
  for i=1 to (n-1) do
    for j=i+1 to n do
      if Random.float 1.0 <= p then
          fprintf pp "e %d %d\n" i j
    done
 done

let _ = 
  Random.self_init();
  let comp=ref 0 in
  let t = Sys.argv in
  try
    if Array.length t = 3 then
        let (n,p) = (int_of_string t.(1),float_of_string t.(2)) in
        if (0.<=p && p<=1.) then
          printf "p edge %d %d\n%t%!" n 0 (random_edges n p) (*** il faut trouver un moyen de connaitre le nb d'aretes créées (pour l'instant j'ai mis 0) *)
        else
          eprintf "Error : p doit être une probabilité\n%!"
    else raise (Failure "")
  with Failure _ -> eprintf "Usage : gen n p\n%!"
  
*)
