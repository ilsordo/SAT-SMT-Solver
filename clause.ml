type variable = int

module OrderedVar = struct
  type t = variable
  let compare = compare
end

(*******)

module VarSet = Set.Make(OrderedVar)

type c_repr = VarSet.t

class varset =
object
  val mutable vis = VarSet.empty
  val mutable hid = VarSet.empty
    
  method repr = vis

  method hide x =
    if (VarSet.mem x vis) then 
      begin
        vis <- VarSet.remove x vis;
        hid <- VarSet.add x hid
      end 
      
  method show x =
    if (VarSet.mem x hid) then
      begin
        hid <- VarSet.remove x hid;
        vis <- VarSet.add x vis
      end
        
  method add x = vis <- VarSet.add x vis
     
  method mem x = VarSet.mem x vis

  method intersects v = VarSet.is_empty (VarSet.inter vis v#repr)

  method union v = {< vis = VarSet.union vis v#repr, hid = VarSet.empty >}

  method is_empty = VarSet.is_empty vis

  method singleton =
    try
      let x = VarSet.max_elt vis in
      if (x = VarSet.min_elt vis) then
        Some x (* Un seul élément x*)
      else
        None (* Au moins 2 éléments *)
    with
      | Not_found -> None (* Vide *)

  method iter f = VarSet.iter f vis 

end
      
(*******)


class clause clause_init =
object
  val vpos = new varset
  val vneg = new varset

  initializer
    List.iter 
      (function 
          | 0 -> assert false
          | x -> 
              if x>0 then 
                vpos#add x
              else  
                vneg#add (-x))
      clause_init
      	
  method get_vpos = vpos
    
  method get_vneg = vneg

  method get_vars = vneg#union vpos
    
  method is_tauto = vpos#intersects vneg
    
  method is_empty = vpos#is_empty && vneg#is_empty

  method vars = vpos#union vneg
  
  method hide_var b x = 
    if b then
      vpos#hide x
    else 
      vneg#hide x

  method show_var b x = 
    if b then
      vpos#show x
    else 
      vneg#show x


  method mem_pos x = vpos#mem x

  method mem_neg x = vneg#mem x

(*
  method get_var_max = (* retourne couple (o,b) où o=None si rien trouvé, Some v si v est la var max. b : booléen indiquant positivité de v*)
    let v1 = 
      try Some (VarSet.max_elt vpos) 
      with Not_found -> None in		
    let v2 = 
      try Some (VarSet.max_elt vneg) 
      with Not_found -> None in
    match (v1,v2) with
      | (None,Some x) -> Some (x,false)
      | (Some x,None) -> Some (x,true)
      | (Some x,Some y) -> 
          if x < y then
            Some (y,false)
          else
            Some (x,true)
      | (None,None) -> None *)
end

(*******)

module OrderedClause = 
struct
  type t = clause
  let compare  = compare
end
