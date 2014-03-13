

module Renommage = Map.Make(String)


class ['a] renommage =
object
  val mutable assoc : ('a) Renommage.t = Renommage.empty

  method mem x = Renommage.mem x assoc
  
  method cardinal = Renommage.cardinal assoc
  
  method add x y = assoc <- Renommage.add x y assoc
  
  method find x = Renommage.find x assoc
  
  method iter f = Renommage.iter f assoc

end



let makefresh () =
  let n = ref 0 in
  fun () -> incr n; string_of_int !n

let signe b = 
  if b then 1 else -1

let rec renommer_clause clause assoc fresh f_new = match clause with 
  | [] -> f_new
  | (b,v)::q -> if (assoc#mem v) then 
                  (renommer_clause q assoc fresh (((signe b)*(assoc#find v))::f_new)) 
                else 
                  begin
                    let x=int_of_string(fresh()) in
                      assoc#add v x;
                      (renommer_clause q assoc fresh ((signe(b)*x)::f_new))
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

  
  


		  
