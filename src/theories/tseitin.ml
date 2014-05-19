
type atom = string

let parse_atom s = s

(* Théorie *)

type etat = unit

let normalize formula = formula
  
let init _ = () 
  
let propagate _ _ etat = etat
  
let backtrack _ _ etat = etat

let get_answer reduc _ values p =
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

