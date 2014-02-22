
type mem = (variable*(variable list)) list


let next_pari formule = (* Some v si on doit faire le prochain pari sur v, None si tout a été parié (et on a donc une affectation gagnante) *)
  let n=formule#get_nb_vars in
  let rec parcours_paris m = 
    if m > n
    then None
    else if formule#is_pari m 
         then parcours_paris (m+1) 
         else Some m
  in parcours_paris 1


(*
class mem n =
object
  val valeurs : bool option array = Array.make (n+1) None
  
  method affect l =
    let v = Array.copy valeurs in
    List.iter (fun (x,b) -> v.(x) <- Some b) l; 
    {< valeurs = v >}
      
  method is_free x = 
    match valeurs.(x) with
      | Some _ -> false
      | None -> true
          
  method get_valeurs = Array.copy valeurs
end
*)

(** tjrs commencer par une propa de contraintes *)
(** traiter la variable parié avant propag *)

let constraint_propagation v mem formule = (* on propage l'affectation effectuée sur v, on met à jour la mémoire et on la renvoie // on a un failwith si une clause est vide *)
  

let dpll formule = (* renvoie true si une affectation a été trouvée, stockée dans paris, false sinon / ou failwith ? *)
  let rec aux mem =
    match constraint_propagation mem formule with
      | None -> 
    let v = choix mem formule in
    match v with
      | None -> mem#valeurs
      | Some x -> 
          begin
            formule#set_var




















