open Clause
open Formule
open Algo_base
open Debug

type clause_classif = Empty | Singleton of literal*int | Top_level_crowded of literal*literal*int | Top_level_singleton of literal*int*literal



(* None si plusieurs littéraux de c sont du niveau (présupposé max) lvl, Some (b,v) si un seul *)
let max_level (formule:formule) etat (c:clause) = 
  let lvl = etat.level in
  let aux b v (res:literal option) =
    if (formule#get_level v) > lvl then
      assert false
    else 
      if (formule#get_level v) = lvl then 
        match res with
          | Some _ ->
              raise Exit 
          | None ->      
              Some (b,v)
      else
        res in
  try
    c#get_vpos#fold_all (aux true) (c#get_vneg#fold_all (aux false) None);
  with Exit -> None
  
(* couple : (2ème niveau le plus élevé après lvl, x) où x=None si clause singleton, Some l si l est un des littéraux du 2ème plus haut niveau *)
let backtrack_level (formule:formule) etat (c:clause) = 
  let lvl = etat.level in
  let aux b v (k,sgt) =
    let lvl_temp = formule#get_level v in
    if (lvl_temp > k && lvl_temp <> lvl) then 
      (lvl_temp,Some (b,v))
    else 
      (k,sgt) in
  let (b_level,sgt) = c#get_vpos#fold_all (aux true) (c#get_vneg#fold_all (aux false) (-1,None)) in (* s'assurer < lvl ? *)
  if sgt = None then
    (0,sgt) (* singleton *)
  else
    (b_level,sgt)
  
(* récupère le littéral en haut de tranche = littéral d'où est parti le conflit *)    
let get_conflict_lit etat = 
  match etat.tranches with
    | [] -> assert false
    | (_,pari,propagation)::q ->
        match propagation with
          | [] -> pari
          | (b,v)::t -> (b,v)
          
let learn_clause (formule:formule) etat c =
  let (bt_lvl,sgt) = backtrack_level formule etat c_learnt in
  begin
    match sgt with (* None si singleton ! *)
      | Some l0 ->
          formule#add_clause c_learnt;
          set_wls formule c_learnt l l0;
          stats#record "Learnt clauses"
      | None -> 
          stats#record "Learnt singletons";
          () (* on n'enregistre pas des singletons *)      
  end;
  (l,bt_lvl,c_learnt)


(* conflit déclenché en pariant le littéral de haut de tranche, dans la clause c
   en résultat : (l,k,c) où : 
      - l : littéral de + haut niveau dans la clause apprise
      - k : niveau auquel backtracker
      - c : clause apprise
*)
let conflict_analysis (formule:formule) etat c =
  let c_learnt = formule#new_clause [] in
  c_learnt#union c; (* initialement, la clause à apprendre est la clause où est apparu le conflit *)
  let rec aux (first,pari,propagation) = 
    match max_level formule etat c_learnt with
      | None -> (* tant qu'il y a plusieurs littéraux du niveau max dans c_learnt... *)
          begin
            match propagation with
              | [] -> 
                  assert false (* pari devrait être le seul littéral du niveau courant dans c_learnt, donc max_level ne devrait pas renvoyer None *)
              | (b,v)::q -> 
                  if (c_learnt#mem_all (not b) v) then (* si c_learnt contient v *)
                    begin
                      match formule#get_origin v with
                        | None -> assert false
                        | Some c -> 
                            c_learnt#union ?v_union:(Some v) c (* on fusionne c_learnt avec la clause à l'origine de l'assignation de v *)
                    end;
                  aux (first,pari,q)
          end
      | Some l -> (* la clause peut être apprise : elle ne contient plus qu'un seul littéral du niveau max *)
          learn_clause formule etat c in
  match etat.tranches with
    | [] -> assert false
    | t::q -> aux t
        









