

module Renommage = Map.Make(String)


class renommage =
object
  val mutable assoc = Renommage.empty

  method mem x = Renommage.mem x assoc
  
  method cardinal = Renommage.cardinal assoc
  
  method add x y = assoc <- Renommage.add x y assoc
  
  method find x = Renommage.find x assoc

end



let concat l1 l2 = (* concatenation de 2 listes *)
  let rec aux l res=match l with
    | [] -> res
    | t::q -> aux q (t::res)
  in aux l1 l2

let makefresh () =
  let n = ref 0 in
  fun () -> incr n; string_of_int !n



let rec renommer_clause clause assoc fresh c_new=  match clause with 
  | [] -> c_new
  | (b,v)::q -> if (assoc#mem v) then 
                  (renommer_clause q assoc fresh ((b,assoc#find v)::c_new)) 
                else 
                  begin
                    let x=fresh() in
                      assoc#add v x;
                      (renommer_clause q assoc fresh ((b,x)::c_new))
                  end

  
let renommer formule = (* renvoie CNF avec vars normalisées + table d'association *)
  let fresh=makefresh() in
  let assoc = new renommage in
  let rec aux f f_new = match f with
    | [] -> f_new
    | t::q -> 
        aux q ((renommer_clause t assoc fresh [])::f_new)
   in
    (aux formule [],assoc) (* formule avec renommage des variables pour format DIMACS + table d'association (ancienne var, var renomée) *)

  
  


		  
