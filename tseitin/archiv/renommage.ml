

module Renommage = Map.Make(String)

let concat l1 l2 = (* concatenation de 2 listes *)
  let rec aux l res=match l with
    | [] -> res
    | t::q -> aux q (t::res)
  in aux l1 l2

let makefresh () =
  let n = ref 0 in
  fun () -> incr n; string_of_int !n


let convert_clause c assoc = (* remplace les noms des variables dans la clause c, d'après la table d'association assoc *)
  let rec aux c res = match c with
		  | [] -> res
		  | (b,v)::q -> if b then aux q ((Renommage.find v assoc)::res) else aux q ((-(Renommage.find v assoc))::res) 
  in aux c []

let convert_formule f assoc = (* remplace les noms des variables dans la formule f, d'après la table d'association assoc *)
  let rec aux f res = match f with
		  | [] -> res
		  | t::q -> aux q ((convert_clause t assoc)::res)
  in aux f []
		  
		  
let renommer formule = (* renvoie formule original + CNF + table d'association. Pour ce restreindre aux vars de départ, on ne regardera pas les _ dans la table *)
  let fresh=makefresh() in (* associe à chaque variable (string) un nombre unique. Permet d'avoir le format DIMACS *)
  let assoc=ref Renommage.empty in
  List.iter 
	  (fun l -> List.iter 
	              (fun (b,s) -> if (not (Renommage.mem s !assoc)) then 
	                              (assoc:=(Renommage.add s fresh() !assoc))
	              ) l
	  ) formule;
  (convert_formule formule !assoc,!assoc)
		  
