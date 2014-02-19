

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

let constraint_propagation mem formule =
  

let dpll formule =
  let rec aux mem =
    match constraint_propagation mem formule with
      | None -> 
    let v = choix mem formule in
    match v with
      | None -> mem#valeurs
      | Some x -> 
          begin
            formule#set_var




















