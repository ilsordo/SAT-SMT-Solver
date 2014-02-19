
type variable = int

(*******)

module OrderedVar = struct
  type t = variable
  let compare = compare
end

module VarSet = Set.Make(OrderedVar)

class varset =
object
  val mutable vis = VarSet.empty
  val mutable hid = VarSet.empty
    
  method get_vis = vis

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
        
  method add x = pos <- VarSet.add x pos
        
  method mem x = VarSet.mem x pos

  method intersects v2 = VarSet.is_empty (VarSet.inter vis v2#get_vis)

  method is_empty = VarSet.is_empty vis

  method singleton =
    (* Moche *)
    try
      let x = VarSet.max_elt pos in
      if (x = VarSet.min_elt pos) then
        Some x (* Un seul élément x*)
      else
        None (* Au moins 2 éléments *)
    with
      | Not_found -> None (* Vide *)
end
      
(*******)


class clause clause_init =
object
  val vpos = new varset
  val vneg = new varset

  initializer
    List.iter 
      (fun 
          | 0 -> assert false
          | x -> 
              if x>0 then 
                vpos#add x
              else  
                vneg#add (-x))
      clause_init
      	
  method get_vpos = vpos
    
  method get_vneg = vneg
    
  method is_tauto = vpos#intersects vneg
    
  method is_empty = vpos#is_empty && vneg#is_empty
  
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
      | (None,None) -> None
end

(*******)

module OrderedClause = struct
  type t = clause
  let compare (c1 : clause) c2 = if (VarSet.equal c1#get_vpos c2#get_vpos)
    then if (VarSet.equal c1#get_vneg c2#get_vneg)
      then 0
      else if (c1#get_vneg < c2#get_vneg)
      then -1
      else 1
      else if (c1#get_vpos < c2#get_vpos) 
      then -1
      else 1
end

module ClauseSet = Set.Make(OrderedClause)

(*******)

class formule n clauses_init =
object (self)
  val mutable nb_var : int = n
  val mutable occurences_pos = Array.make (n+1) ClauseSet.empty (* clauses dans lesquelles chaque var apparait positivement *)
  val mutable occurences_pos_hidden = Array.make ClauseSet.empty
  val mutable occurences_neg = Array.make (n+1) ClauseSet.empty (* clauses dans lesquelles chaque var apparait négativement *)
  val mutable occurences_neg_hidden = Array.make (n+1) ClauseSet.empty
  val mutable clauses = ClauseSet.empty		(* ensemble des clauses de la formule *)
  val mutable clauses_hidden = ClauseSet.empty

  (*val mutable valeur : bool option array = Array.make (n+1) None  (* affectation des variables *)*)

  initializer
    List.iter 
      (fun 
          | [] -> ()
          | t::q -> let v = new clause t in clauses <- ClauseSet.add v clauses)
      clause_init;
    ClauseSet.iter 
      (fun c -> (VarSet.iter 
                   (fun v ->  occurences_pos.(v) <- ClauseSet.add c occurences_pos.(v) ) 
                   c#get_vpos);
        VarSet.iter 
          (fun v ->  occurences_neg.(v) <- ClauseSet.add c occurences_neg.(v) ) 
          c#get_vneg)) 
      clauses

  method get_nb_var = n

  method get_occurences_pos i = occurences_pos.(i)

  method get_occurences_neg i = occurences_neg.(i)

  method add_clause c = 
    clauses <- ClauseSet.add c clauses;
    ClauseSet.iter (fun v -> ClauseSet.add c occurences_pos.(v)) c#get_vpos;
    ClauseSet.iter (fun v -> ClauseSet.add c occurences_neg.(v)) c#get_vneg

  method get_clauses = clauses

  method set_val_pos x = 
    ClauseSet.iter
      (fun c -> x#hide_var_neg x)
      occurences_neg.(x);
    clauses <- ClauseSet.diff clauses occurences_pos.(x)
    clauses_hidden <- ClauseSet.union clauses_hidden occurences_pos.(x)
  
  method reset x =
    ClauseSet.iter
      (fun c -> x#hide_var_neg x)
      occurences_neg.(x);
    clauses <- ClauseSet.diff clauses occurences_pos.(x);
    clauses_hidden <- ClauseSet.union clauses_hidden occurences_pos.(x)
      
    
  (*method set_val k b = valeur.(k) <- Some b

  method unset k = valeur.(k) <- None
    
  method get_val k = valeur.(k)*)

  method remove_clause c = 
    clauses <- ClauseSet.remove c clauses;
    ClauseSet.iter (fun v -> ClauseSet.remove c occurences_pos.(v)) c#get_vpos;
    ClauseSet.iter (fun v -> ClauseSet.remove c occurences_neg.(v)) c#get_vneg

   (*   
  method fusion_clauses (c1:clause) (c2:clause) (vv : variable) = 
    let c = new clause in (* c est la fusion des clauses c1 et c2 suivant la variable vv *)
    clauses <- ClauseSet.add c clauses;
    VarSet.iter (fun v -> c#add_vpos v) c1#get_vpos ;
    VarSet.iter (fun v -> c#add_vneg v) c1#get_vneg ;
    VarSet.iter (fun v -> c#add_vpos v) c2#get_vpos ;
    VarSet.iter (fun v -> c#add_vneg v) c2#get_vneg ;		
    c#remove_var vv; (* on supprime vv de c, car la fusion s'est effectuée selon vv *)						
    c	(* on renvoie c *)
   *) 

 (* method eval_clause c = (* indique si la clause c est vraie avec les valeurs actuelles *)
    (VarSet.exists 
      (fun v -> match (self#get_val v) with 
                  | Some b -> b 
                  | None -> false )  
       c#get_vpos) || 
    (VarSet.exists 
      (fun v -> match (self#get_val v) with 
                  | Some b -> not b 
                  | None -> false ) 
      c#get_vneg)  *)


end
