open Sys
open Printf

let shuffle tab n =
  for i = 0 to n-1 do
      let x = Random.int (Array.length tab - i) + i in (* on peut remplacer Array.length tab par n ? j'ai l'impression que ça n'impact pas la rapidité *)
      let v = tab.(x) in
      tab.(x) <- tab.(i);
      tab.(i) <- v
  done
    

let make_tab k = Array.init k (fun x -> x + 1)

let print_tab l p tab =
  for i = 0 to l-1 do
    let s = if Random.bool() then "" else "-" in
    fprintf p "%s%d " s tab.(i)
  done

let gen_formule n l k p =
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










