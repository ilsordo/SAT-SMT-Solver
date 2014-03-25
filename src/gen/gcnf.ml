open Config_random
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

let random_cnf n l k p = (* génère une formule aléatoire de n variables et k clauses de longueur l chacune *)
  let tab = (make_tab n) in
  for i = 1 to k do
    shuffle tab l;
    fprintf p "%a0\n" (print_tab l) tab
  done

let gen () = 
  let (n,l,k) = (config.param1,config.param2,config.param3) in
    if (l<=n) then
      printf "p cnf %d %d\n%t%!" n k (random_cnf n l k)
    else
      eprintf "Error : la taille des clauses est supérieure au nombre de variables (l>n)\n%!"
