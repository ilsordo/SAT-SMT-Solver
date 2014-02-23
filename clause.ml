type variable = int

module OrderedVar = struct
  type t = variable
  let compare = compare
end

(*******)

module VarSet = Set.Make(OrderedVar)

type c_repr = VarSet.t

class varset =
object (self : 'varset)
  val mutable vis = VarSet.empty (* variables visibles du varset *)
  val mutable hid = VarSet.empty (* variables cachées du varset *)
    
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
        
  method add x = vis <- VarSet.add x vis (* si x est déjà dans hid : si on le cache/montre il ne sera plus qu'à un endroit *)
     
  method mem x = VarSet.mem x vis  (* indique si la variable x est dans vis  *)

  method intersects (v : 'varset) = VarSet.is_empty (VarSet.inter vis v#repr) (* indique si l'intersection entre vis et v est vide ou non *)

  method union (v : 'varset) = {< vis = VarSet.union vis v#repr; hid = VarSet.empty >} (* on renvoie une nouveau varset *)

  method is_empty = VarSet.is_empty vis

  method size = VarSet.cardinal vis

  method singleton = (* indique si vis est un singleton *)
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
  val vpos = new varset (* grâce au varset, on va pouvoir cacher ou non des variables dans vpos, ou vneg *)
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

  method get_vars = vneg#union vpos (* renvoie un varset union de toutes les var visibles *)
    
  method is_tauto = vpos#intersects vneg
    
  method is_empty = vpos#is_empty && vneg#is_empty
  
  method hide_var b x = (* b = true si x est une litteral positif, false si négatif *)
    if b then
      vpos#hide x
    else 
      vneg#hide x

  method show_var b x = 
    if b then
      vpos#show x
    else 
      vneg#show x

  method mem b x = 
    if b then
      vpos#mem x
    else
      vneg#mem x

  method singleton = (* renvoie Some (x,b) si la clause est un singleton ne contenant que x avec la positivité b *)
    match (vpos#singleton, vneg#singleton) with
      | (None, None)
      | (Some _, Some _) -> None
      | (Some v, None) -> Some (v,true)
      | (None, Some v) -> Some (v,false)

end

(*******)

module OrderedClause = 
struct
  type t = clause
  let compare  = compare (** est-ce une bonne fonction de comparaison ? *)
end
