open Sys
open Printf

let shuffle tab n = (* applique une permutation circulaire aléatoire sur le tableau tab de taille n *)
  for i = 0 to n-1 do
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
  for i = 1 to k do
    let tab = (make_tab n) in
    shuffle tab n;
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










