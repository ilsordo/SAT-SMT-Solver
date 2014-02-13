

class variable n =
object
  val nom : int = n
  (*  val mutable visible = true
  *)
  method get_nom = nom
(*
  method is_visible = visible
  
  method show = visible <- true

  method hide = visible <- false
*)

    
end

(*******)

module OrderedVar = struct
  type t = variable
  let compare (v1 : variable) v2 = v1#get_nom - v2#get_nom
end

module VarSet = Set.Make(OrderedVar)


(*******)


class clause clause_init =
object
  val mutable vpos = VarSet.empty (* variable apparaissant positivement dans la clause *)
  val mutable vneg = VarSet.empty (* variable apparaissant négativement dans la clause *)

  val mutable vpos_hidden = VarSet.empty
  val mutable vneg_hidden = VarSet.empty

  initializer
    List.iter 
      (fun 
          | 0 -> assert false
          | x -> 
              let v = new variable x in
              if x>0 then 
                vpos <- VarSet.add v vpos
              else  
                vneg <- VarSet.add v vneg)
      clause_init
      
  (* une même variable peut être dans vpos et vneg == tautologie *)
  (*
    method add_vpos v = vpos <- VarSet.add v vpos
    
    method add_vneg v = vneg <- VarSet.add v vneg
  *)
  method remove_var v = 
    vpos <- VarSet.remove v vpos;
    vneg <- VarSet.remove v vneg
      
  method get_vpos = vpos
    
  method get_vneg = vneg
    
  method is_tauto = not (VarSet.is_empty (VarSet.inter vpos vneg))
    
  method is_empty = (VarSet.is_empty vpos) && (VarSet.is_empty vneg)
    
  method get_var_max = 
    let v1 = 
      try Some (VarSet.max_elt vpos) 
      with Not_found -> None in		(* s'assurer avant qu'au moins vpos ou vneg est non nul *)
    let v2 = 
      try Some (VarSet.max_elt vneg) 
      with Not_found -> None in
    match (v1,v2) with
      | (None,Some x) -> Some (x,false)
      | (Some x,None) -> Some (x,true)
      | (Some x,Some y) -> 
          if x#get_nom < y#get_nom then
            Some (y,false)
          else
            Some (x,true)
      | (None,None) -> None
          
(* renvoie la plus grande variable de la clause, et 1 si elle apparait positivement, -1 sinon *)  
          
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
  val mutable occurences_pos = Array.make (n+1) ClauseSet.empty (* variables apparaissant positivement dans la formule *)
  val mutable occurences_neg = Array.make (n+1) ClauseSet.empty (* variables apparaissant négativement dans la formule *)
  val mutable valeur : bool option array = Array.make (n+1) None  (* affectation des variables *)
  val mutable clauses = ClauseSet.empty		(* clauses qui constituent la formule *)

  method get_nb_var = n

  method get_occurences_pos i = occurences_pos.(i)

  method get_occurences_neg i = occurences_neg.(i)
    
  method add_clause c = 
    clauses <- ClauseSet.add c clauses;
    ClauseSet.iter (fun v -> ClauseSet.add c occurences_pos.(v#get_nom)) c#get_vpos;
    ClauseSet.iter (fun v -> ClauseSet.add c occurences_neg.(v#get_nom)) c#get_vneg
      
  method get_clauses = clauses
    
  method set_val k b = valeur.(k) <- Some b

  method unset k = valeur.(k) <- None
    
  method get_val k = valeur.(k)

  method remove_clause c = 
    clauses <- ClauseSet.remove c clauses;
    ClauseSet.iter (fun v -> ClauseSet.remove c occurences_pos.(v#get_nom)) c#get_vpos;
    ClauseSet.iter (fun v -> ClauseSet.remove c occurences_neg.(v#get_nom)) c#get_vneg
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
  method eval_clause c = (VarSet.exists (fun v -> ((self#get_val v#get_nom) = 1) )  c#get_vpos) || 
    (VarSet.exists (fun v -> ((self#get_val v#get_nom) = 0) )  c#get_vneg)  (* indique si la clause c est vraie avec les valeurs actuelles *)

  method set_clause_faux cs = ClauseSet.exists (fun c -> not (self#clause_vraie c)) cs	(* vrai si l'ensemble de clause cs contient une clause fausse avec les valeurs actuelles, faux sinon *)

end
