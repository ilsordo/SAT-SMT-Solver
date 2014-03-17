module Values = Map.Make(String)
module Names = Map.Make(struct type t = int let compare = compare end)


(* Table de correspondance entre des chaines de caractères et des noms de variables (int) *)
class renommage =
object (self)
  (* l'objet gère ses variables fraiches *)
  val mutable count = 0

  val mutable values : int Values.t = Values.empty

  val mutable names : string Names.t = Names.empty
  
  (* Variable maximale utilisée *)
  method max = count

  method private get_fresh = 
    count <- count + 1;
    count
  
  method bind s =
    assert (not (Values.mem s values)); (* Par sécurité *)
    let x = self#get_fresh in
    values <- Values.add s x values;
    names <- Names.add x s names;
    x
  
  method get_value s = 
    try 
      Some (Values.find s values)
    with Not_found -> None

  method get_name x = 
    try 
      Some (Names.find x names)
    with Not_found -> None
      
  
  method iter f = Values.iter f values

end

let signe b = 
  if b then 1 else -1

(** J'ai réécrit les fonctions suivantes avec map *)

(*
let rec renommer_clause assoc fresh f_new = function
  | [] -> f_new
  | (b,v)::q -> if (assoc#mem v) then 
                  (renommer_clause q assoc fresh (((signe b)*(assoc#find v))::f_new)) 
                else 
                  begin
                    let x=int_of_string(fresh()) in
                      assoc#add v x;
                      (renommer_clause q assoc fresh ((signe(b)*x)::f_new))
                  end
*)

let renommer_clause assoc =
  let renommer_litteral (b,v) =
    let x = match assoc#get_value v with
      | Some x -> x
      | None -> assoc#bind v in
    signe b * x in
  List.map renommer_litteral

  
let renommer f = (* renvoie CNF avec vars normalisées + table d'association *)
  let assoc = new renommage in
  (*let rec aux f f_new = match f with 
    | [] -> f_new
    | t::q -> 
        aux q ((renommer_clause assoc fresh [] t)::f_new)
   in
    (aux formule [],assoc)*)
  (List.map (renommer_clause assoc) f, assoc)
 (* formule avec renommage des variables pour format DIMACS + table d'association (ancienne var, var renomée) *)


(* énumère les f(n0), f(n0 + 1) , etc *)
class ['a] counter n0 (f:int->'a) =
object
  val mutable n = n0 - 1

  method next = n <- n + 1; f n
end
