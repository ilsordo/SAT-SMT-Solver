
module Association = Map.Make(String)

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
  
  
  
(*
let convert_clause c assoc = (* remplace les noms des variables dans la clause c, d'après la table d'association assoc *)
  let rec aux c res = match c with
		  | [] -> res
		  | (b,v)::q -> if b then aux q ((Association.find v assoc)::res) else aux q ((-(Association.find v assoc))::res) 
  in aux c []

let convert_formule f assoc = (* remplace les noms des variables dans la formule f, d'après la table d'association assoc *)
  let rec aux f res = match f with
		  | [] -> res
		  | t::q -> aux q ((convert_clause t assoc)::res)
  in aux f []
		  
		  
		  		                   
let color formule k = (* renvoie formule original + CNF + table d'association. Pour ce restreindre aux vars de départ, on ne regardera pas les _ dans la table *)
  let c_formule = color_to_cnf formule k in
    let m=ref 1 in (* associe à chaque variable (string) un nombre unique. Permet d'avoir le format DIMACS *)
    let assoc=ref Association.empty in
  		List.iter 
		  (fun l -> List.iter 
		              (fun (b,s) -> if (not (Association.mem s !assoc)) then 
		                              (assoc:=(Association.add s !m !assoc); incr m)
		               ) l
		  ) c_formule;
  (c_formule,convert_formule c_formule !assoc,!assoc)
		  
*)		  
		  
