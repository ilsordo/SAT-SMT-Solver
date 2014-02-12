
open Formule

class seaux k =
object (self)
  val mutable nb_var = k
  val mutable cpos = Array.make (k+1) ClauseSet.empty	(* cpos.(k) contient les clauses dont xk est la plus grande variable, et telles que xk y apparait positivement *)
  val mutable cneg = Array.make (k+1) ClauseSet.empty (* cneg.(k) contient les clauses dont xk est la plus grande variable, et telles que xk y apparait négativement *)

  method get_nb_var = nb_var
	
  method add_cpos c k = (cpos.(k) <- ClauseSet.add c cpos.(k))
 
  method add_cneg c k = cneg.(k) <- ClauseSet.add c cneg.(k)
	
  method add_c c = if (c#is_empty)
				   				 then failwith "unsatis" (* on a trouvé une clause vide *)
				  				 else if (not (c#is_tauto)) 
												then begin
											          let (v,p) = c#get_var_max in if p=1 
																														 then self#add_cpos c v#get_nom 
													   									  						 else self#add_cneg c v#get_nom
											  	   end

  method nettoie_seaux k = let f c cs = if (ClauseSet.exists (fun cc -> (VarSet.subset cc#get_vpos c#get_vpos) 
																																		&& (VarSet.subset cc#get_vneg c#get_vneg)) cs)
									   									 then cs
									   									 else ClauseSet.add c (ClauseSet.diff cs (ClauseSet.filter (fun cc -> (VarSet.subset c#get_vpos cc#get_vpos) 
																																																				 && (VarSet.subset c#get_vneg cc#get_vneg)) cs)) 	
													in cpos.(k) <- ClauseSet.fold f cpos.(k) ClauseSet.empty;
						  							 cneg.(k) <- ClauseSet.fold f cneg.(k) ClauseSet.empty
(* nettoie_seaux k parcours toutes les clauses de cpos.(k) et supprime toutes les clauses c1 telles qu'il existe une clause c2 incluse dans c1, il effectue de même ppour cneg.(k) *)
													   
  method get_cpos k = cpos.(k)
	
  method get_cneg k = cneg.(k)
	
end


(**************)

let davis_putnam f = (* retourne l'ensemble des seaux après exécution complête de l'algo de davis-putnam *)
	let s = new seaux (f#get_nb_var) in
	ClauseSet.iter (fun c -> let (v,p) = c#get_var_max in if p=1 
														  													then s#add_cpos c (v#get_nom)
														  													else s#add_cneg c (v#get_nom)  ) f#get_clau ; (* on a initialisé les seaux *)
	for k=f#get_nb_var downto 2 do
		if (Array.length Sys.argv>2 && Sys.argv.(2) = "-clean") then s#nettoie_seaux k; (* !!! l'option -clean accélère grandement le programme *)
		if (not (ClauseSet.is_empty (s#get_cpos k) || ClauseSet.is_empty (s#get_cneg k)))	(* si le seau k ne contient pas que des pos ou des neg on engendre tous les résultants possibles *)
		then ClauseSet.iter (fun c -> ClauseSet.iter (fun cc -> let ccc = (f#fusion_clause c cc (f#get_var k)) in s#add_c ccc
											  												 ) (s#get_cneg k)
												) (s#get_cpos k) (* on a engendré tous les résultants à partir du seau k *)
	done; (* il reste à observer le seau 1 *)
	if (not (ClauseSet.is_empty (s#get_cpos 1) || ClauseSet.is_empty (s#get_cneg 1))) (* si le seau 1 contient des les clauses {x1} et {non x1} *)
	then failwith "unsatis";	(* alors il n'y a pas de solution *)
	s (* sinon, on retourne s *)
	

(**************)
	 
let affecter f = (* construit une affectation des variables, à partir des seaux renvoyés par davis_putnam *)
		let s = davis_putnam f in (* on récupère les seaux après exécution de davis_putnam *)
		for k = 1 to f#get_nb_var do (* on parcourt les seaux à partir du 1 *)
			if (ClauseSet.is_empty (s#get_cpos k))	(* si cpos.(k) est vide *)
			then f#set_val k 0	(* alors il est facile d'affecter xk : xk=0 *)
			else if (ClauseSet.is_empty (s#get_cneg k)) (* idem si cneg.(k) est vide *)
				 	 then f#set_val k 1
				 	 else if (f#set_clause_faux (s#get_cpos k)) (* sinon, si on trouve une clause de cpos.(k) qui n'est pas vraie avec l'affectation par défaut (xk=0) *)
					  		then f#set_val k 1 (* alors on met xk=1 *)
					  		else f#set_val k 0 (* sinon, on maintient l'affectation par défaut : xk=0 *)
		done
