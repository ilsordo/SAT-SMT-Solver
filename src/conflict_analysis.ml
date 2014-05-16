open Clause
open Formule
open Algo_base
open Debug

type clause_classif = Empty | Singleton of literal*int | Top_level_crowded of literal*literal*int | Top_level_singleton of literal*int*literal*int

(* besoin des 2 littéraux dans crowded ? *)

let backtrack_analysis (formule:formule) etat (c:clause) = (* description de la clause*)
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
  match backtrack_analysis formule etat c with
    | Empty -> raise Unsat
    | Singleton (l,lvl) ->
        stats#record "Learnt singletons"; 
        Var_depth (etat.level,l) (* on n'enregistre pas la clause, on backtrack jusqu'au niveau 0 = etat.level étapes de bckt à faire, on assigne l *)
    | Top_level_crowded (l1,l2,lvl_max) ->
        formule#add_clause c;
        set_wls formule c l1 l2;
        Clause_depth (etat.level-lvl_max,c) (* on bckt au niveau lvl_max, on analyse la clause pour défaire partiellement ce niveau *)
    | Top_level_singleton (l1,lvl_max,l2,lvl_next) -> 
        formule#add_clause c;
        set_wls formule c l1 l2; 
        Var_depth (etat.level-lvl_next,l1) (* on bckt au niveau lvl_next, on assigne l1 *)
    
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
      | Top_level_singleton (l1,_,_,lvl_next) -> 
          let _ = learn_clause formule etat c_learnt in
          (l1,lvl_next,c_learnt)
      | Singleton (l,_) -> (* lvl_max = 0 *)
          let _ = learn_clause formule etat c_learnt in
          (l,0,c_learnt)
  in match etat.tranches with
    | [] -> assert false
    | (_,propagation)::q -> aux propagation





