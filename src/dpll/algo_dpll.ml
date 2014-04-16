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

let init n cnf =
  let f = new formule_dpll in
  f#init n cnf;
  f#check_empty_clause; (** peut lever Init_empty*)
  try
    let _ = constraint_propagation f [] in
      { formule = f; tranches = [] ; level = 0}
  with Conflit_prop -> Init_empty
    
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
let make_bet (b,v) etat ?(cl=false) =
  let lvl = etat.level + 1 in 
  let etat = increase_level etat in (***)
    begin
      try
        etat.formule#set_val b v lvl
      with 
        Clause_vide (l,c) -> 
          raise (Conflit (l,c,{ etat with tranches = ((b,v),[])::etat.tranches } )) (* l=(not b,v) ?*)
    end;
    try 
      let propagation = constraint_propagation etat.formule [] cl lvl in
        { etat with tranches = ((b,v),propagation)::etat.tranches }
    with
      Conflit_prop (l,c,acc) -> 
        raise (Conflit (l,c,{ etat with tranches = ((b,v),acc)::etat.tranches } ))

(** POURSUIVRE UN PARI *)

(* va compléter la dernière tranche
   assigne (b,v) (ce n'est pas un pari) puis propage *)
let continue_bet (b,v) etat = 
  let lvl=etat.level in
    match etat.tranches with
      | [] -> assert false 
      | (pari,propagation)::q ->
          begin
            try
              etat.formule#set_val b v lvl
            with 
              Clause_vide (l,c) -> 
                raise (Conflit (l,c,{ etat with tranches = (pari,(b,v)::propagation) } ))(* On a créé une clause vide en poursuivant le pari *)
          end;
          try 
            let continue_propagation = constraint_propagation etat acc cl in
              { etat with tranches = (pari,continue_propagation) }
          with
            Conflit_prop (l,c,acc) -> 
              raise (Conflit (l,c,{ etat with tranches = (pari,acc) } ))


(** CONSTRAINT_PROPAGATION *)

(* propage en ajoutant à acc les littéraux assignés
   si cl est vrai, enregistre les clauses ayant provoqué chaque assignation *)
let rec constraint_propagation etat acc ?(cl=false) =
  let formule = etat.formule in
  let lvl =  etat.level in
    match formule#find_singleton with 
      | None ->
          begin
          match formule#find_single_polarite with
              | None -> acc
              | Some (b,v) ->   
                  try
                    debug#p 3 "Propagation : single polarity found : %d %B" v b;
                    debug#p 4 "Propagation : setting %d to %B" v b;
                    if cl then
                      formule#set_val b v c lvl (* on sauvegarde aussi la clause ayant provoqué l'assignation *)
                    else
                      formule#set_val b v lvl; 
                    constraint_propagation formule ((b,v)::acc) cl lvl (* on empile et on poursuit *)
                  with                 
                    Clause_vide (l,c) -> raise (Conflit_prop (l,c,(b,v)::acc)) (* en fait l = (b,v) ? *)
          end
      | Some ((b,v),c) ->
          try
            debug#p 3 "Propagation : singleton found : %d %B" v b;
            debug#p 4 "Propagation : setting %d to %B" v b;
          if cl then
              formule#set_val b v c lvl
            else
              formule#set_val b v lvl;
          constraint_propagation formule ((b,v)::acc) cl lvl
        with
            Clause_vide (l,c) -> raise (Conflit_prop (l,c,(b,v)::acc))

    
(**CONFLICT_ANALYSIS *)
    
let max_level c lvl = (* None si plusieurs littéraux de c sont du niveau (présupposé max) lvl, Some (b,v) si un seul *)
  let aux b v res =
    if (etat.formule#get_level v) > lvl then
      assert false
    else if (etat.formule#get_level v) = lvl && res != None then
      raise Exit 
    else if (etat.formule#get_level v) = lvl && res = None then
      Some (b,v)
    else
      None in
  try
    c#get_vpos#fold (aux true) (c#get_vpos#fold (aux false) (0,None))  (*** récupérer les littéraux cachés *)
  with Exit -> None
  
  
let snd_level c lvl = (* 2ème niveau le plus élevé après lvl*)
  let aux v k =
    if (etat.formule#get_level v) != lvl then max (etat.formule#get_level v) k else k in
  c#get_vpos#fold aux (c#get_vpos#fold aux 0)  (* s'assurer < lvl ? *) (*** récupérer les littéraux cachés *)
    
    
(* conflit déclenché en pariant le littéra de haut de tranche, dans la clause c
   en résultat : (l,k,c) où : 
      - l : littéral de + haut niveau dans la clause apprise
      - k : niveau auquel backtracker
      - c : clause apprise
*)
let conflict_analysis etat c =
  let lvl = etat.level in 
  let c_learnt = (etat.formule#new_clause) in
  let rec aux (pari,propagation) = 
    match max_level c_learnt with
      | None ->
          match propagation with
            | [] -> 
                begin
                  c_learnt#union c (snd pari); (*** union sur littéraux cachés aussi *)
                  aux (pari,[]) (* c'est risqué, il faut bien que c_learnt contienne un seul littéral du niveau max *)
                end
            | (b,v)::q -> 
                begin
                  if (c_learnt#mem_cl b v) then 
                    begin
                      match (etat.formule)#get_origin v with
                        | None -> assert false
                        | Some c -> 
                            c_learnt#union c v (*** attention union sur des var cachées *)
                     end;
                  aux (pari,q)
              end
      | Some (b,v) -> 
          ((b,v),snd_level c_learnt lvl,c_learnt) (*** RESULT *) (**enregister la clause*)
    
    
    
    
