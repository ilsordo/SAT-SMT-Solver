open Clause
open Formule
open Algo_base
open Debug

type clause_classif = Empty | Singleton of literal*int | Top_level_crowded of literal*literal*int | Top_level_singleton of literal*int*literal*int


let backtrack_analysis (formule:formule) etat (c:clause) = 
  let aux b v classif = 
    let lvl = formule#get_level v in
    match classif with
      | Empty -> Singleton ((b,v),lvl)      
      | Singleton (l,lvl_max) when lvl = lvl_max -> Top_level_crowded (l,(b,v),lvl)
      | Singleton (l,lvl_max) when lvl > lvl_max -> Top_level_singleton ((b,v),lvl,l,lvl_max)
      | Singleton (l,lvl_max) -> Top_level_singleton (l,lvl_max,(b,v),lvl)            
      | Top_level_crowded (l1,l2,lvl_max) when lvl > lvl_max -> Top_level_singleton ((b,v),lvl,l1,lvl_max)
      | Top_level_crowded (l1,l2,lvl_max) -> Top_level_crowded (l1,l2,lvl_max)   
      | Top_level_singleton (l1,lvl_max,l2,lvl_next) when lvl = lvl_max -> Top_level_crowded (l1,(b,v),lvl_next)
      | Top_level_singleton (l1,lvl_max,l2,lvl_next) when lvl > lvl_max -> Top_level_singleton ((b,v),lvl,l1,lvl_max)
      | Top_level_singleton (l1,lvl_max,l2,lvl_next) when lvl > lvl_next -> Top_level_singleton (l1,lvl_max,(b,v),lvl)
      | Top_level_singleton (l1,lvl_max,l2,lvl_next) -> Top_level_singleton (l1,lvl_max,l2,lvl_next)   
  in      
    c#get_vpos#fold_all (aux true) (c#get_vneg#fold_all (aux false) Empty)

    
let learn_clause (formule:formule) etat c =
  match backtrack_analysis formule etat c_learnt with
    | Empty -> raise Unsat
    | Singleton (l,lvl) ->
        stats#record "Learnt singletons"; 
        (Some l,0,c)
    | Top_level_crowded (l1,l2,lvl_max) ->
        formule#add_clause c;
        set_wls formule c l1 l2; 
        (None,lvl_max,c)
    | Top_level_singleton (l1,lvl_max,l2,lvl_next) -> 
        formule#add_clause c;
        set_wls formule c l1 l2; 
        (Some l1,lvl_next,c)  
    
(* conflit déclenché en pariant le littéral de haut de tranche, dans la clause c
   en résultat : (l,k,c) où : 
      - l : littéral de + haut niveau dans la clause apprise
      - k : niveau auquel backtracker
      - c : clause apprise
*)
let conflict_analysis (formule:formule) etat c =
  let c_learnt = formule#new_clause [] in
  c_learnt#union c; (* initialement, la clause à apprendre est la clause où est apparu le conflit *)
  let rec aux propagation = 
    match backtrack_analysis formule etat c_learnt with
      | Empty -> assert false
      | Top_level_crowded _ -> 
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
                  aux q
          end
      | Top_level_singleton (_,_,l2,lvl_next) -> 
          learn_clause formule etat c_learnt;
          (l2,lvl_next,c_learnt)
      | Singleton (l,_) -> (* lvl_max = 0 *)
          learn_clause formule etat c_learnt;
          (l,0,c_learnt)
  in match etat.tranches with
    | [] -> assert false
    | (_,propagation)::q -> aux propagation









