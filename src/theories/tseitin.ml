
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
  let print_var name id =
    if name <> "" && name.[0] <> '_' then
      let s = if values#find id = Some true then "" else "-" in
      Printf.fprintf p "v %s%s\n" s name in
  assoc#iter print_var
  
let pure_prop = true

