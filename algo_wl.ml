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

(***************************************************)

(* constraint_propagation reçoit un ordre d'assignation de b sur la variable var : 
      elle doit faire cette assignation et toutes celles qui en découlent, ssi pas de conflits créées
      si conflits, aucune assignation ne doit être faite + toutes les variables figurant dans l doivent être dé-assignées
      si réussit : renvoie la liste des assignations effectuées
*)
(* l : liste des assignations effectuées depuis le dernier pari, inclu *)
let rec constraint_propagation (formule : Formule_wl.formule_wl) var b l =
  debug 3 "Assignation %B sur variable %d" b var; 
  formule#get_paris#set var b; (* on pari b sur var *)
  (formule#get_wl (not b,var))#fold  (* on parcourt  les clauses où var est surveillée et est devenue fausse, ie là où il faut surveiller un nouveau litteral *) 
    (fun c l_next -> match (formule#update_clause c (not b,var)) with
      | WL_Conflit -> 
         debug 3 "Conflit dans clause %d (tentative d'abandon du wl (%B,%d))" c#get_id (fst l_next) (snd l_next); 
         formule#get_paris#remove var;
         List.iter (fun v -> formule#get_paris#remove v) l_next;
         raise Wl_fail
      | WL_New -> 
          debug 3 "Déplacement de jumelle dans clause %d (abandon du wl (%B,%d))" c#get_id (fst l_next) (snd l_next); 
          l_next
      | WL_Assign (b_next,v_next) -> 
          debug 3 "Assignation %B demandée sur variable %d (abandon du wl (%B,%d))" b_next v_next (fst l_next) (snd l_next);  
          constraint_propagation formule v_next b_next l_next
      | WL_Nothing -> 
          debug 3 "Aucune conséquence, clause %d déjà vraie (tentative d'abandon du wl (%B,%d))" c#get_id (fst l_next) (snd l_next); 
          l_next
    ) (var::l)


(*************)



let algo n cnf =
  let formule = new formule_wl in

  let rec aux()= (* aux fait un pari et essaye de le prolonger le plus loin possible *)
    match next_pari formule with
      | None -> 
          debug 1 "Aucun pari disponible"; 
          true (* plus rien à parier = c'est gagné *)
      | Some var ->  
          debug 1 "Pari à venir sur variable %d" var ; 
          try 
            debug 2 "Pari à true sur variable %d" var; 
            let l = (constraint_propagation formule var true []) in (* lève une exception si conflit créé, sinon renvoie liste des vars assignées *)
              if aux () then (* si on réussit à poursuivre l'assignation jusqu'au bout *)
                begin
                  debug 1 "Assignation trouvée pour l'ensemble de la formule (à partir de propagation pari à true sur variable %d)" var; 
                  true (* c'est gagné *)
                end
              else (* pb plus loin dans le backtracking, il faut tout annuler pour parier sur faux *)
                begin
                  debug 2 "Echec du pari à true sur variable %d" var ;  
                  List.iter (
                    fun v -> debug 2 "Assignation annulée sur variable %d (à partir de propagation pari à true sur variable %d)" v var;
                    formule#get_paris#remove v
                  ) l; (* on annule les assignations *)
                  raise Wl_fail
                end
          with
            | Wl_fail ->   
                try 
                  debug 2 "Pari à false sur variable %d" var ; 
                  let l = constraint_propagation formule var false [] in (* on a encore une chance sur le faux *)
                  if aux () then (* si on réussit à poursuivre l'assignation jusqu'au bout *)
                    begin
                     debug 1 "Assignation trouvée pour l'ensemble de la formule (à partir de propagation pari à false sur variable %d)" var; 
                     true (* c'est gagné *)
                     end
                  else
                    begin
                      debug 2 "Echec du pari à false sur variable %d" var ;  
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







