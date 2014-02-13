class mem  =
object
  method is_free x = not (VarSet.mem x valeurs)
end

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




















