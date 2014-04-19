open Algo
open Clause
open Debug
open Formule_dpll
open Formule

(** la règle pour le level c'est : 
      seul undo peut le diminuer
      seul make_bet peut l'augmenter *)

let name = "Dpll"

type formule = formule_dpll

let init n cnf = 
  let f = new formule_dpll in
  let etat = { tranches = []; level = 0 } in (* On peut le jeter ou il faut le renvoyer? *)
    f#init n cnf;
    f#check_empty_clause; (* peut lever Unsat *)
    try
      let _ = constraint_propagation f etat [] in
        f
    with Conflit_prop _ -> raise Unsat
    
let decrease_level etat = { etat with level = etat.level-1 }

let increase_level etat = { etat with level = etat.level+1 }

let get_formule (formule:formule) = (formule:>Formule.formule)


(** CONSTRAINT_PROPAGATION *)

(* propage en ajoutant à acc les littéraux assignés
   si cl est vrai, enregistre les clauses ayant provoqué chaque assignation *)
let rec constraint_propagation (formule:formule) etat acc =
  let lvl = etat.level in
    match formule#find_singleton with 
      | None ->
          begin
          match formule#find_single_polarite with
              | None -> acc
              | Some (b,v) ->   
                  try
                    debug#p 3 "Propagation : single polarity found : %d %B" v b;
                    debug#p 4 "Propagation : setting %d to %B" v b;
                    formule#set_val b v lvl;
                    constraint_propagation formule etat ((b,v)::acc) (* on empile et on poursuit *)
                  with                 
                    Empty_clause c -> raise (Conflit_prop (c,(b,v)::acc)) 
          end
      | Some ((b,v),c) ->
          try
            debug#p 3 "Propagation : singleton found : %d %B in clause %d" v b c#get_id;
            debug#p 4 "Propagation : setting %d to %B" v b;
            formule#set_val b v ~cl:c lvl;
            constraint_propagation formule etat ((b,v)::acc)
          with
            Empty_clause c -> raise (Conflit_prop (c,(b,v)::acc))

(** PARIER*)

(* pari sur (b,v) puis propage
   pose la dernière tranche, quoiqu'il arrive
*)
let make_bet (formule:formule) (b,v) etat =
  let etat = increase_level etat in (***)
  let lvl = etat.level in 
    begin
      try
        formule#set_val b v lvl
      with 
        Empty_clause c -> 
          raise (Conflit (c,{ etat with tranches = ((b,v),[])::etat.tranches } ))
    end;
    try 
      let propagation = constraint_propagation formule etat [] in
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
      let _ = constraint_propagation formule etat [] in (* peut lever Conflit_prop *)
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
            let continue_propagation = constraint_propagation formule etat ((b,v)::propagation) in
              { etat with tranches = (pari,continue_propagation)::q }
          with
            Conflit_prop (c,acc) -> 
              raise (Conflit (c,{ etat with tranches = (pari,acc)::q } ))

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
  let aux v k =
    if (formule#get_level v) <> lvl then max (formule#get_level v) k else k in
  let b_level = c#get_vpos#fold_all aux (c#get_vneg#fold_all aux (-1)) in (* s'assurer < lvl ? *)
    if b_level = -1 then
      (0,true) (* singleton *)
    else
      (b_level,false)
      
      
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
                  if (c_learnt#mem_all (not b) v) then (** bien remarquer le not *)
                    begin
                      match formule#get_origin v with
                        | None -> assert false
                        | Some c -> 
                            c_learnt#union ?v_union:(Some v) c
                    end;
                  aux (pari,q)
          end
      | Some (b,v) -> 
          begin
            let (bt_lvl,sgt) = backtrack_level formule etat c_learnt in
            if not sgt then (* on n'enregistre pas des singletons *)
              formule#add_clause c_learnt;
            ((b,v),bt_lvl,c_learnt)  (** pas de not ici *)
          end in
  match etat.tranches with
    | [] -> assert false
    | t::q -> aux t
    


