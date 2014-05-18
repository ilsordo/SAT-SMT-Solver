
type atom = string

let parse_atom s = s
  
let print_atom p a = ()

(* Théorie *)

type etat = unit

let normalize formula = formula
  
let init reduc = () 
  
let propagate reduc prop etat = etat
  
let backtrack reduc undo_list etat = etat

let get_answer reduc etat values p =
  reduc#iter
    (fun s v -> 
      match values#find v with
        | None -> assert false
        | Some b -> if b then Printf.fprintf p "v %s\n" s else Printf.fprintf p "v -%s\n" s)
  (*
  let print_var name id =
    if name <> "" && name.[0] <> '_' then
      let s = if values#find id = Some true then "" else "-" in
      Printf.fprintf p "v %s%s\n" s name in
  assoc#iter print_var
  *)
  
let pure_prop = true

