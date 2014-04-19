open Algo
open Clause
open Debug
open Formule_wl
open Formule

let name = "Wl"

type formule = formule_wl

(** CONSTRAINT_PROPAGATION *)
       
let constraint_propagation (formule : formule) (b,v) etat acc = (* Assigne (b,v) et propage, renvoie la liste de tous les littéraux assignés *)
  let lvl = etat.level in
  let rec assign (b,v) c acc = 
    debug#p 5 "Propagation : setting %d to %B" v b;
    try
      formule#set_val b v ~cl:c lvl; (* on parie b sur var *)
      debug#p 3 "WL : Moving old wl's on (%B,%d)" (not b) v;
      (* on parcourt  les clauses où var est surveillée et est devenue fausse, ie là où il faut surveiller un nouveau littéral *) 
      (formule#get_wl (not b,v))#fold (propagate (b,v)) ((b,v)::acc)
    with
      | Empty_clause c -> raise (Conflit_prop (c,(b,v)::acc))
  and propagate (b,v) c acc = (* update des jumelles de c (suivant (b,v)), propage, renvoie les assignations effectuées *)
    match (formule#update_clause c (not b,v)) with
      | WL_Conflit ->
          stats#record "Conflits";
          debug#p 2 ~stops:true "WL : Conflict : clause %d false " c#get_id;
          debug#p 4 "Propagation : cannot leave wl %B %d in clause %d" (not b) v c#get_id; 
          raise (Conflit_prop (c,acc))
      | WL_New (b_new, v_new) -> 
          debug#p 4 "Propagation : watched literal has moved from %B %d to %B %d in clause %d" (not b) v b_new v_new c#get_id ; 
          acc
      | WL_Assign (b_next,v_next) -> 
          debug#p 4 "Propagation : setting %d to %B in clause %d is necessary (leaving %B %d impossible)" v_next b_next c#get_id (not b) v; 
          assign (b_next,v_next) c acc
      | WL_Nothing -> 
          debug#p 4 "Propagation : clause %d satisfied (leaving wl %B %d unnecessary)" c#get_id (not b) v; 
          acc
  in
    (formule#get_wl (not b,v))#fold (propagate (b,v)) acc


(** Fonctions générales *)

let init n cnf = (* initialise la formule et renvoie un état *)
  let f = new formule_wl in
  (*let etat = { tranches = []; level = 0 } in*)
    f#init n cnf;  (* fait des assignations, contrairement à DPLL, mais ne trouve pas d'éventuels conflits *)
    f#check_empty_clause; (* peut lever Unsat *)
    f#init_wl; (* pose les jumelles *)
    f
  
let decrease_level etat = { etat with level = etat.level-1 }

let increase_level etat = { etat with level = etat.level+1 }

let get_formule (formule:formule) = (formule:>Formule.formule)


(** Annuler des assignations *)

let undo_assignation formule (_,v) = formule#reset_val v

let rec undo ?(depth=1) formule etat = 
  if depth=0 then
    etat
  else 
    match etat.tranches with (* annule la dernière tranche et la fait sauter *)
      | [] -> assert false 
      | (pari,propagation)::q ->
          begin
            List.iter (undo_assignation formule) propagation;
            undo_assignation formule pari;
            undo ~depth:(depth-1) formule (decrease_level { etat with tranches = q })
          end
  
  
(** PARIER*)

(* pari sur (b,v) puis propage
   pose la dernière tranche, quoiqu'il arrive
*)
let make_bet (formule:formule) (b,v) etat =
  let etat = increase_level etat in
  let lvl = etat.level in 
    begin
      try
        formule#set_val b v lvl
      with 
        Empty_clause c -> 
          raise (Conflit (c,{ etat with tranches = ((b,v),[])::etat.tranches } ))
    end;
    try 
      let propagation = constraint_propagation formule (b,v) etat [] in (*** ICI : une diff avec DPLL *)
        { etat with tranches = ((b,v),propagation)::etat.tranches }
    with
      Conflit_prop (c,acc) -> 
        raise (Conflit (c,{ etat with tranches = ((b,v),acc)::etat.tranches } ))
        
        
(** POURSUIVRE UN PARI *)

(* va compléter la dernière tranche
   assigne (b,v) (ce n'est pas un pari) puis propage
   sgt = true si b v est un singleton *)

let continue_bet (formule:formule) (b,v) c_learnt etat = 
  let lvl=etat.level in
  if lvl=0 then
    try
      formule#set_val b v lvl; (* peut lever Empty_clause *)
      let _ = constraint_propagation formule (b,v) etat [] in (* peut lever Conflit_prop *)  (*** ICI : une diff avec DPLL *)
        etat
    with _ -> raise Unsat (*** ou mettre Backtrack etat pour avoir recup au même niveau entre cl et non cl*)
  else    
    match etat.tranches with
      | [] -> assert false 
      | (pari,propagation)::q ->
          begin
            try
              formule#set_val b v ~cl:c_learnt lvl
            with 
              Empty_clause c -> 
                raise (Conflit (c,{ etat with tranches = (pari,(b,v)::propagation)::q } ))
          end;
          try 
            let continue_propagation = constraint_propagation formule (b,v) etat ((b,v)::propagation) in  (*** ICI : une diff avec DPLL *)
              { etat with tranches = (pari,continue_propagation)::q }
          with
            Conflit_prop (c,acc) -> 
              raise (Conflit (c,{ etat with tranches = (pari,acc)::q } ))
              
              
(**CONFLICT_ANALYSIS *)


let max_level (formule:formule) etat (c:clause) = (* None si plusieurs littéraux de c sont du niveau (présupposé max) lvl, Some (b,v) si un seul *)
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
  
  
let backtrack_level (formule:formule) etat (c:clause) = (* 2ème niveau le plus élevé après lvl, lvl-1 si singleton *)
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
  
      
let get_conflict_lit etat = (* récupère le littéral en haut de tranche, qui est le littéral d'où est parti le conflit *)
  match etat.tranches with
    | [] -> assert false
    | (pari,propagation)::q ->
        match propagation with
          | [] -> pari
          | (b,v)::t -> (b,v)
          
(* conflit déclenché en pariant le littéra de haut de tranche, dans la clause c
   en résultat : (l,k,c) où : 
      - l : littéral de + haut niveau dans la clause apprise
      - k : niveau auquel backtracker
      - c : clause apprise
      - sgt : bool indiquant si la clause apprise est singleton ou non
*)
let conflict_analysis (formule:formule) etat c =
  let c_learnt = formule#new_clause in
  c_learnt#union c;
  let rec aux (pari,propagation) = 
    match max_level formule etat c_learnt with
      | None ->
          begin
            match propagation with
              | [] -> 
                  assert false (* pari devrait être le seul littéral du niveau courant  dans c_learnt, donc max_level ne devrait pas renvoyer None *)
              | (b,v)::q -> 
                  if (c_learnt#mem_all (not b) v) then
                    begin
                      match formule#get_origin v with
                        | None -> assert false
                        | Some c -> 
                            c_learnt#union ?v_union:(Some v) c
                    end;
                  aux (pari,q)
          end
      | Some l -> 
          begin
            let (bt_lvl,sgt) = backtrack_level formule etat c_learnt in
              begin
                match sgt with
                  | Some l0 ->
                      formule#add_clause c_learnt;
                      formule#set_wl l l0 c_learnt  (*** ICI : une diff avec DPLL *)
                  | None -> () (* on n'enregistre pas des singletons *)      
              end;
            (l,bt_lvl,c_learnt)
          end in
  match etat.tranches with
    | [] -> assert false
    | t::q -> aux t
    
    




