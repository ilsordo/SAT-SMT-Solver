open Formule
open Formule_wl
open Clause
open Debug
open Answer


exception Wl_fail

let print_valeur p v = function
  | true -> Printf.fprintf p "v %d\n" v
  | false -> Printf.fprintf p "v -%d\n" v

let print_answer p = function
  | Unsolvable -> Printf.fprintf p "s UNSATISFIABLE\n"
  | Solvable valeurs -> 
      Printf.fprintf p "s SATISFIABLE\n";
      valeurs#iter (print_valeur p)

(***************************************************)


let next_pari formule = (* Some v si on peut faire le prochain pari sur v, None si tout a été parié *)
  let n=formule#get_nb_vars in
  let rec parcours_paris = function
    | 0 -> None
    | m -> 
        if (formule#get_pari m != None) then 
          parcours_paris (m-1) 
        else 
          Some m in
  parcours_paris n


(* constraint_propagation reçoit un ordre d'assignation de b sur la variable var : 
      elle doit faire cette assignation et toutes celles qui en découlent, ssi pas de conflits créées
      si conflits, aucune assignation ne doit être faite + toutes les variables figurant dans l doivent être dé-assignées
      si réussit : renvoie la liste des assignations effectuées
*)
(* l : liste des assignations effectuées depuis le dernier pari, inclu *)
let rec constraint_propagation formule var b l =
  if ((formule#get_paris#find var) = Some (not b)) then (* tentative de double paris contradictoires  *)
    begin
      debug 2 "Tentative assignations doubles contradictoire sur variable %d " var ;
      List.iter (fun v -> debug 3 "Assignation annulée sur variable %d (suite à assignations doubles contradictoire)" v ; formule#get_paris#remove v) !l; (* on annule toutes les assignations depuis le dernier pari *)
      raise Wl_fail
    end
  else
    begin
      debug 2 "Assignation %B sur variable %d " b var ;
      l := (var::(!l)); (* se rappeler que v subit une assignation *)
      formule#get_paris#set var b (* on fait l'assignation sans risque *)
    end;
  let deplacer = (*il faut deplacer des jumelles *)
    if b then
      formule#get_wl_neg var 
    else
      formule#get_wl_pos var in
  deplacer#iter (fun c -> match formule#update_clause c (not b,var) with
    | WL_Conflit -> debug 3 "Jumelles bloquée sur false (traitement de variable %d assignée a %B dans clause %d) " var b c#get_id;
        List.iter (fun var -> debug 3 "Assignation annulée sur variable %d  dans clause %d (suite à jumelles bloquées)" var c#get_id; formule#get_paris#remove var) !l; (* on annule toutes les assignations depuis le dernier pari *)
        raise Wl_fail
    | WL_New -> debug 3 "Jumelles déplacées (traitement de variable %d assignée a %B  dans clause %d) " var b c#get_id;
    | WL_Assign (bb,v) -> debug 1 "Jumelles demande assignement %B sur variable %d (traitement de variable %d assignée a %B  dans clause %d) " bb v var b c#get_id;let _ = constraint_propagation formule v bb l in ()
    | WL_Nothing -> debug 3 "Jumelles immobiles (traitement de variable %d assignée a %B  dans clause %d) " var b c#get_id; ()  );
  !l (* on renvoie toutes les assignations effectuées *)




let algo n cnf =
  let formule = new formule_wl in

  let rec aux()= (* aux fait un pari et essaye de le prolonger le plus loin possible *)
    match next_pari formule with
      | None -> debug 1 "Aucun pari disponible"; true (* plus rien à parier = c'est gagné *)
      | Some var ->  debug 1 "Pari à venir sur variable %d" var ; 
          try 
            debug 1 "Pari à true sur variable %d" var; 
            let l = constraint_propagation formule var true (ref []) in (* première chance en pariant vrai *)
            if aux () then (* si on réussit à poursuivre l'assignation jusqu'au bout *)
              true (* c'est gagné *)
            else (* pb plus loin dans le backtracking, il faut tout annuler pour parier sur faux *)
              begin
                debug 1 "Echec du pari à true sur variable %d" var ;  
                List.iter (fun var -> debug 1 "Pari à true annulé sur variable %d " var ; formule#get_paris#remove var) l; (* on annule les assignations *)
                raise Wl_fail
              end
          with
            | Wl_fail ->   
                try 
                  debug 1 "Pari à false sur variable %d" var ; 
                  let l=constraint_propagation formule var false (ref []) in (* on a encore une chance sur le faux *)
                  if aux () then (* si on réussit à poursuivre l'assignation jusqu'au bout *)
                    true (* c'est gagné *)
                  else
                    begin
                      debug 1 "Echec du pari à false sur variable %d" var ;  
                      List.iter (fun var -> debug 1 "Pari à false annulé sur variable %d " var ; formule#get_paris#remove var) l; (* sinon il faut backtracker sur le pari précédent *)
                      false
                    end   
                with
                  | Wl_fail -> false
  in

  try
    formule#init n cnf; (* on a prétraité, peut être des clauses vides créées >> détectées ligne en dessous *)
    formule#check_empty_clause; (* détection de clauses vides *)
    formule#init_wl; (* Les jumelles sont initialisées *)
    (* à partir de maintenant : pas de clauses vides, singleton ou tautologie. De plus, un ensemble de var a été assigné (et enlevées des clauses) sans conflits *)
    if aux () then 
      Solvable formule#get_paris
    else 
      Unsolvable
  with
    | Clause_vide -> Unsolvable (* Clause vide dès le début *)







