open Algo
open Clause
open Debug
open Formule_dpll
open Formule

type etat = { formule : formule_dpll; tranches : tranche list ; level : int }
(** la règle pour le level c'est : 
      seul undo peut le diminuer
      seul make_bet peut l'augmenter *)

let name = "Dpll"



  
  
(***)


let init n cnf = (*** A VERIFIER *)
  let f = new formule_dpll in
  let etat = { formule = f; tranches = [] ; level = 0} in
    f#init n cnf;
    f#check_empty_clause; (** peut lever Init_empty*)
    try
      let _ = constraint_propagation etat [] in
        etat
    with Conflit_prop _ -> Init_empty
    
let decrease_level etat = { etat with level = etat.level-1 }

let increase_level etat = { etat with level = etat.level+1 }

let get_formule { formule = formule ; _ } = (formule:>formule)


(** Annuler des assignations *)

let undo_assignation formule (_,v) = formule#reset_val v

let rec undo etat =  match etat.tranches with (* annule la dernière tranche et la fait sauter *)
    | [] -> assert false 
    | (pari,propagation)::q ->
        List.iter (undo_assignation etat.formule) propagation;
        undo_assignation etat.formule pari;
        decrease_level { etat with tranches = q } 
        
  
(** PARIER*)

(* pari sur (b,v) puis propage
   pose la dernière tranche, quoiqu'il arrive
   renvoie l'etat si pas de conflit
           Conflit (l,c,etat) si conflit sur littéral l dans c
*)
let make_bet (b,v) etat =
  let lvl = etat.level + 1 in 
  let etat = increase_level etat in (***)
    begin
      try
        etat.formule#set_val b v lvl
      with 
        Clause_vide c -> 
          raise (Conflit (c,{ etat with tranches = ((b,v),[])::etat.tranches } )) (* (not b,v) ?*)
    end;
    try 
      let propagation = constraint_propagation etat [] in
        { etat with tranches = ((b,v),propagation)::etat.tranches }
    with
      Conflit_prop (c,acc) -> 
        raise (Conflit (c,{ etat with tranches = ((b,v),acc)::etat.tranches } ))

(** POURSUIVRE UN PARI *)

(* va compléter la dernière tranche
   assigne (b,v) (ce n'est pas un pari) puis propage *)
let continue_bet (b,v) sgt etat = 
  let lvl=etat.level in
  if lvl=0 then
    try
      etat.formule#set_val b v lvl;
      let _ = constraint_propagation etat [] in
        etat
    with _ -> raise Init_empty (*** message non pertinent *)
  else    
    match etat.tranches with
      | [] -> assert false 
      | (pari,propagation)::q ->
          begin
            try
              if sgt then
                etat.formule#set_val b v 0 (** ça ne devrait pas provoquer de clause vide à ce niveau*)
              else
                etat.formule#set_val b v lvl
            with 
              Clause_vide c -> 
                if sgt then (* enlever ce if then else si tout marche *)
                  assert false
                else
                  raise (Conflit (c,{ etat with tranches = (pari,(b,v)::propagation) } ))(* not b ?*)
          end;
          try 
            let continue_propagation = constraint_propagation etat ((b,v)::propagation) in (** acc ? et b v ?*)
              { etat with tranches = (pari,continue_propagation) }
          with
            Conflit_prop (c,acc) -> 
              raise (Conflit (c,{ etat with tranches = (pari,acc) } ))


(** CONSTRAINT_PROPAGATION *)

(* propage en ajoutant à acc les littéraux assignés
   si cl est vrai, enregistre les clauses ayant provoqué chaque assignation *)
let rec constraint_propagation etat acc =
  let formule = etat.formule in
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
                    formule#set_val b v lvl; (* on sauvegarde aussi la clause ayant provoqué l'assignation *)
                    constraint_propagation etat ((b,v)::acc) (* on empile et on poursuit *)
                  with                 
                    Clause_vide c -> raise (Conflit_prop (c,(b,v)::acc)) (* not b ?*)
          end
      | Some ((b,v),c) ->
          try
            debug#p 3 "Propagation : singleton found : %d %B" v b;
            debug#p 4 "Propagation : setting %d to %B" v b;
            formule#set_val b v c lvl;
            constraint_propagation etat ((b,v)::acc)
          with
            Clause_vide c -> raise (Conflit_prop (c,(b,v)::acc)) (* not b ?*)

    
(**CONFLICT_ANALYSIS *)
    
let max_level etat c = (* None si plusieurs littéraux de c sont du niveau (présupposé max) lvl, Some (b,v) si un seul *)
  let formule = etat.formule in
  let lvl = etat.level in
  let aux b v res =
    if (formule#get_level v) > lvl then
      assert false
    else if (formule#get_level v) = lvl && res != None then
      raise Exit 
    else if (formule#get_level v) = lvl && res = None then
      Some (b,v)
    else
      None in
  try
    c#get_vpos#fold_all (aux true) (c#get_vneg#fold_all (aux false) None)  (*** récupérer les littéraux cachés *)
  with Exit -> None
  
  
let backtrack_level etat c = (* 2ème niveau le plus élevé après lvl, lvl-1 si singleton *)
  let formule = etat.formule in
  let lvl = etat.level in
  let aux k v =
    if (etat.formule#get_level v) != lvl then max (etat.formule#get_level v) k else k in
  let b_level = c#get_vpos#fold_all aux (c#get_vneg#fold_all aux -1) in (* s'assurer < lvl ? *) (*** récupérer les littéraux cachés *)
    if b_level = -1 then
      (lvl-1,true) (* singleton *)
    else
      (b_level,false)
      
      
let get_lit_conflit etat = 
  match etat.tranches with
    | [] -> assert false
    | (pari,propagation)::q ->
        match propagation with
          begin
            | [] -> pari
            | (b,v)::t -> (b,v)
          end
          
(* conflit déclenché en pariant le littéra de haut de tranche, dans la clause c
   en résultat : (l,k,c) où : 
      - l : littéral de + haut niveau dans la clause apprise
      - k : niveau auquel backtracker
      - c : clause apprise
*)
let conflict_analysis etat c =
  let formule = etat.formule in
  let lvl = etat.level in 
  let c_learnt = formule#new_clause in
  let (b_conflit,v_conflit) = get_lit_conflit etat in 
  c_learnt#union c v_conflit; (***)
  let rec aux (pari,propagation) = 
    match max_level etat c_learnt with
      | None ->
          match propagation with
            | [] -> 
                assert false (* pari devrait être le seul littéral au niveau courant *)
            | (b,v)::q -> 
                begin
                  if (c_learnt#mem_all b v) then (* et not b ?*)
                    begin
                      match formule#get_origin v with
                        | None -> assert false
                        | Some c -> 
                            c_learnt#union c v (*** attention union sur des var cachées *)
                     end;
                  aux (pari,q)
                end
      | Some (b,v) -> 
          begin
            formule#add_clause c_learnt; (***)
            let (bt_lvl,sgt)=backtrack_level etat c_learnt in (***)
              ((b,v),bt_level,sgt) (** pas la peine de renvoyer etat ? *)
          end in
  match etat.tranches with
    | [] -> assert false
    | t::q -> aux t
    
    
    
