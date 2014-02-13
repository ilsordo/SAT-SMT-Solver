
type variable = int

(*
class variable n =
object
<<<<<<< HEAD
  val nom : int = n
  (*  val mutable visible = true
  *)
  method get_nom = nom
(*
  method is_visible = visible
  
  method show = visible <- true

  method hide = visible <- false
*)

    
=======
  val nom = abs n

  method get_nom = nom
   
>>>>>>> 1a137cf94fb5e7b289f96d1133ad7782a8995f14
end
*)

(*******)

module OrderedVar = struct
  type t = variable
  let compare = compare
end

module VarSet = Set.Make(OrderedVar)


(*******)


class clause clause_init =
object
  val mutable vpos = VarSet.empty (* variable apparaissant positivement dans la clause *)
  val mutable vneg = VarSet.empty (* variable apparaissant négativement dans la clause *)

  val mutable vpos_hidden = VarSet.empty (* variables cachées, forcèment absentes de vpos *)
  val mutable vneg_hidden = VarSet.empty

  initializer
    List.iter 
      (fun 
          | 0 -> assert false
          | x -> 
              if x>0 then 
                vpos <- VarSet.add x vpos
              else  
                vneg <- VarSet.add (abs x) vneg)
      clause_init
      
<<<<<<< HEAD
  (* une même variable peut être dans vpos et vneg == tautologie *)
  (*
    method add_vpos v = vpos <- VarSet.add v vpos
    
    method add_vneg v = vneg <- VarSet.add v vneg
  *)
  method remove_var v = 
    vpos <- VarSet.remove v vpos;
    vneg <- VarSet.remove v vneg
      
=======
(* une même variable peut être dans vpos et vneg == tautologie *)

(*
  method add_vpos v = vpos <- VarSet.add v vpos
 
  method add_vneg v = vneg <- VarSet.add v vneg
*)
  method remove_var v = (* supprime aussi v des variables cachées *)
    vpos <- VarSet.remove v vpos;
    vneg <- VarSet.remove v vneg;
    vpos_hidden <- VarSet.remove v vpos_hidden;
    vneg_hidden <- VarSet.remove v vneg_hidden
	
>>>>>>> 1a137cf94fb5e7b289f96d1133ad7782a8995f14
  method get_vpos = vpos
    
  method get_vneg = vneg
    
  method is_tauto = not (VarSet.is_empty (VarSet.inter vpos vneg))
    
  method is_empty = (VarSet.is_empty vpos) && (VarSet.is_empty vneg)
<<<<<<< HEAD
    
  method get_var_max = 
=======
  
  method hide_var_pos x = (* déplace x vers vpos_hidden ssi elle est déjà dans vpos *)     
    if (VarSet.mem x vpos)
    then (vpos_hidden <- VarSet.add v vpos_hidden; vpos <- VarSet.remove v vpos)

  method hide_var_neg x =     
    if (VarSet.mem x vneg)
    then (vneg_hidden <- VarSet.add v vneg_hidden; vneg <- VarSet.remove v vneg)

  method show_var_pos x = (* déplace x vers vpos ssi elle est déjà dans vpos_hidden *)     
    if (VarSet.mem x vpos_hidden)
    then (vpos_hidden <- VarSet.remove v vpos_hidden; vpos <- VarSet.add v vpos)

  method show_var_neg x = 
    if (VarSet.mem x vneg_hidden)
    then (vneg_hidden <- VarSet.remove v vneg_hidden; vneg <- VarSet.add v vneg)

  method mem_pos v = VarSet.mem v vpos

  method mem_neg v = VarSet.mem v vneg

  method get_var_max = (* retourne couple (o,b) où o=None si rien trouvé, Some v si v est la var max. b : booléen indiquant positivité de v*)
>>>>>>> 1a137cf94fb5e7b289f96d1133ad7782a8995f14
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
<<<<<<< HEAD
          
(* renvoie la plus grande variable de la clause, et 1 si elle apparait positivement, -1 sinon *)  
          
=======
    
>>>>>>> 1a137cf94fb5e7b289f96d1133ad7782a8995f14
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
  val mutable occurences_neg = Array.make (n+1) ClauseSet.empty (* clauses dans lesquelles chaque var apparait négativement *)
  (*val mutable valeur : bool option array = Array.make (n+1) None  (* affectation des variables *)*)
  val mutable clauses = ClauseSet.empty		(* ensemble des clauses de la formule *)

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
<<<<<<< HEAD
    ClauseSet.iter (fun v -> ClauseSet.add c occurences_pos.(v#get_nom)) c#get_vpos;
    ClauseSet.iter (fun v -> ClauseSet.add c occurences_neg.(v#get_nom)) c#get_vneg
      
=======
    ClauseSet.iter (fun v -> ClauseSet.add c occurences_pos.(v)) c#get_vpos;
    ClauseSet.iter (fun v -> ClauseSet.add c occurences_neg.(v)) c#get_vneg
    
>>>>>>> 1a137cf94fb5e7b289f96d1133ad7782a8995f14
  method get_clauses = clauses

  method set_val_pos x = 
    ClauseSet.iter
      (fun c -> c#hide_var_pos x) 
      occurences_pos.(x);
  
    
  (*method set_val k b = valeur.(k) <- Some b

  method unset k = valeur.(k) <- None
    
  method get_val k = valeur.(k)*)

  method remove_clause c = 
    clauses <- ClauseSet.remove c clauses;
<<<<<<< HEAD
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
=======
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
>>>>>>> 1a137cf94fb5e7b289f96d1133ad7782a8995f14

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
