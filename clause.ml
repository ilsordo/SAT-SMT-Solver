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

  method hide x = (* déplace la variable x des variables visibles aux variables cachées (ssi elle est déjà visible) *)
    if (VarSet.mem x vis) then 
      begin
        vis <- VarSet.remove x vis;
        hid <- VarSet.add x hid
      end 
      
  method show x = (* déplace la variable x des variables cachées aux variables visibles (ssi elle est déjà cachée) *) 
    if (VarSet.mem x hid) then
      begin
        hid <- VarSet.remove x hid;
        vis <- VarSet.add x vis
      end
        
  method add x = vis <- VarSet.add x vis (* ajoute x aux vars visibles // si x était déjà dans hid : après, si on le cache/montre, il ne sera plus que ds 1 endroit *)
     
  method mem x = VarSet.mem x vis  (* indique si la variable x est dans vis  *)

  method intersects (v : 'varset) = VarSet.is_empty (VarSet.inter vis v#repr) (* indique si l'intersection entre vis et v est vide ou non *)

  method union (v : 'varset) = {< vis = VarSet.union vis v#repr; hid = VarSet.empty >} (* renvoie une nouveau varset, union de vis et v *)

  method is_empty = VarSet.is_empty vis

  method size = VarSet.cardinal vis (* nombre de variables visibles *)

  method singleton = (* indique si vis est un singleton, et renvoie Some v si v est l'unique variable de vis, None sinon *)
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
  val vpos = new varset (* grâce au varset, on va pouvoir cacher ou non des variables dans vpos. De même dans vneg *)
  val vneg = new varset

  initializer (* construction d'une clause à partir d'une liste d'entier *)
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

  method get_vars = vneg#union vpos (* renvoie un varset union de toutes les vars visibles *)
    
  method is_tauto = vpos#intersects vneg (* indique si la clause est une tautologie *)
    
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

  method mem b x = (* indique si x est présent dans la clause avec la positivite b *)
    if b then
      vpos#mem x
    else
      vneg#mem x

  method singleton = (* renvoie Some (x,b) si la clause est un singleton ne contenant que x avec la positivité b, None sinon *)
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
  let compare (c1 : t) c2 = if (VarSet.equal c1#get_vpos#repr c2#get_vpos#repr) then
                              if (VarSet.equal c1#get_vneg#repr c2#get_vneg#repr) then
                                0
                              else
                                if (c1#get_vneg#repr < c2#get_vneg#repr) then
                                  -1
                                else
                                  1
                            else 
                              if (c1#get_vpos#repr < c2#get_vpos#repr) then
                                -1
                              else
                                1
                              
 (** est-ce une bonne fonction de comparaison ? ne faut-il pas la redéfinir avec des Set.equal ? *)
end
