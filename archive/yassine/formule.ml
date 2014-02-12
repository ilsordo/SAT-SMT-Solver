

class variable n =
object
	val mutable nom : int = n

  method get_nom = nom
	
end

(*******)

module OrderedVar = struct
  type t = variable
  let compare (v1 : variable) v2 = v1#get_nom - v2#get_nom
end

module VarSet = Set.Make(OrderedVar)


(*******)


class clause =
object
  val mutable vpos = VarSet.empty (* variable apparaissant positivement dans la clause *)
  val mutable vneg = VarSet.empty (* variable apparaissant négativement dans la clause *)
(* une même variable peut être dans vpos et vneg == tautologie *)

  method add_vpos v = vpos <- VarSet.add v vpos
 
  method add_vneg v = vneg <- VarSet.add v vneg

  method remove_var v = vpos <- VarSet.remove v vpos ; vneg <- VarSet.remove v vneg
	
  method get_vpos = vpos
  
  method get_vneg = vneg
	
  method is_tauto = not (VarSet.is_empty (VarSet.inter vpos vneg))
  
  method is_empty = (VarSet.is_empty vpos) && (VarSet.is_empty vneg)
  
  method get_var_max = let v1 = try VarSet.max_elt vpos with Not_found -> new variable 0 in		(* s'assurer avant qu'au moins vpos ou vneg est non nul *)
					   					 let v2 = try VarSet.max_elt vneg with Not_found -> new variable 0 in
													if v1#get_nom < v2#get_nom then (v2,-1) else (v1,1)					
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

class formule n =
object (self)
  val mutable nb_var : int = n
  val mutable var = Array.make (n+1) (new variable 0) (* variables apparaissant dans la formule *)
  val mutable valeur = Array.make (n+1) 0 (* affectation des variables : valeur[i]=1 si xi est vraie, -1 si xi est faux *)
  val mutable clau = ClauseSet.empty		(* clauses qui constituent la formule *)

  method get_nb_var = n

	method get_var i = var.(i)
  
  method add_var v i = var.(i) <- v
    
  method add_clau c = clau <- ClauseSet.add c clau
  
  method get_clau = clau
  
  method set_val k i = valeur.(k) <- i

  method get_val k = valeur.(k)

  method remove_clause c = clau <- ClauseSet.remove c clau
  
  method fusion_clause (c1:clause) (c2:clause) (vv : variable) = let c = new clause in (* c est la fusion des clauses c1 et c2 suivant la variable vv *)
							   																										begin
																																			clau <- ClauseSet.add c clau;
																																			VarSet.iter (fun v -> c#add_vpos v) c1#get_vpos ;
																																			VarSet.iter (fun v -> c#add_vneg v) c1#get_vneg ;
																																			VarSet.iter (fun v -> c#add_vpos v) c2#get_vpos ;
																																			VarSet.iter (fun v -> c#add_vneg v) c2#get_vneg ;		
																																			c#remove_var vv; (* on supprime vv de c, car la fusion s'est effectuée selon vv *)						
																																			c	(* on renvoie c *)
							   																										end

	method clause_vraie c = (VarSet.exists (fun v -> ((self#get_val v#get_nom) = 1) )  c#get_vpos) || 
													(VarSet.exists (fun v -> ((self#get_val v#get_nom) = 0) )  c#get_vneg)  (* indique si la clause c est vraie avec les valeurs actuelles *)

	method set_clause_faux cs = ClauseSet.exists (fun c -> not (self#clause_vraie c)) cs	(* vrai si l'ensemble de clause cs contient une clause fausse avec les valeurs actuelles, faux sinon *)

end



