open Clause
open Formule
open Debug
open Answer

type tranche = literal * literal list 

type 'a result = Fine of 'a | Backtrack of 'a

type t = Heuristic.t -> bool -> int -> int list list -> Answer.t

let neg : literal -> literal = function (b,v) -> (not b, v)

type etat = {
  tranches : tranche list;
  level : int
  (*vsids : int vartable*) (***) 
}

exception Conflit_prop of (clause*(literal list)) (* permet de construire une tranche quand conflit trouvé dans prop *)

exception Conflit of (clause*etat)



module type Algo_base =
sig
  type formule = private #formule (* J'ai trouvé! *)

  val name : string

  val init : int -> int list list -> formule (* construction de la formule, prétraitement *)

  val constraint_propagation : formule -> literal -> etat -> literal list -> literal list

  val set_wls : formule -> clause -> literal -> literal -> unit (* Nom pas très générique mais compréhensible *)

end



module Bind = functor(Base : Algo_base) ->
struct

  include Base

  let decrease_level etat = { etat with level = etat.level-1 }

  let increase_level etat = { etat with level = etat.level+1 }

  (* Parie sur (b,v) puis propage. Pose la dernière tranche,
     quoiqu'il arrive *)
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
      let propagation = constraint_propagation formule (b,v) etat [] in
      { etat with tranches = ((b,v),propagation)::etat.tranches }
    with
        Conflit_prop (c,acc) -> 
          raise (Conflit (c,{ etat with tranches = ((b,v),acc)::etat.tranches } ))

  (* Compléte la dernière tranche, assigne (b,v) (ce n'est pas un
     pari) puis propage. sgt = true si c_learnt est le singleton (b,v)*)
  let continue_bet (formule:formule) (b,v) c_learnt etat = 
    let lvl=etat.level in
    if lvl=0 then
      try
        formule#set_val b v lvl; (* peut lever Empty_clause *)
        let _ = constraint_propagation formule (b,v) etat [] in (* peut lever Conflit_prop *)
        etat
      with _ -> raise Unsat
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
              let continue_propagation = constraint_propagation formule (b,v) etat ((b,v)::propagation) in
              { etat with tranches = (pari,continue_propagation)::q }
            with
                Conflit_prop (c,acc) -> 
                  raise (Conflit (c,{ etat with tranches = (pari,acc)::q } ))

  let undo_assignation formule (_,v) = formule#reset_val v

  let undo ?(depth=1) (formule:formule) etat = (** A VERIFIER *)
    stats#start_timer "Bactrack (s)"; (***)
    let rec aux depth etat =
      if depth=0 then
        etat
      else 
        match etat.tranches with (* annule la dernière tranche et la fait sauter *)
          | [] -> assert false 
          | (pari,propagation)::q ->
              begin
                List.iter (undo_assignation formule) propagation;
                undo_assignation formule pari;
                aux (depth-1) (decrease_level { etat with tranches = q })
              end
    in
      let res = aux depth etat in
      stats#stop_timer "Bactrack (s)"; (***)
      res
      
  (** Conflict analysis *)

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
                match sgt with (* None si singleton *)
                  | Some l0 ->
                      formule#add_clause c_learnt;
                      set_wls formule c_learnt l l0
                  | None -> () (* on n'enregistre pas des singletons *)      
              end;
              (l,bt_lvl,c_learnt)
            end in
    match etat.tranches with
      | [] -> assert false
      | t::q -> aux t
      
      
      
  let shake_up formule  =
    let replace_wl c b v (l0,l1) = (* si (b,v) est vrai et est plus vieux et différent que l0 ou l1, alors prend sa place *)
      match formule#get_pari v with  (* (b,v) est vrai *)
        | Some b_pari when b_pari=b -> 
           begin
             let k = formule#get_level v in
             if (snd l0 = v || snd l1 = v) then
               (l0,l1)
             else
               match (formule#get_pari (snd l0),formule#get_pari (snd l1)) with
                 |(Some b0,Some b1) -> 
                    let (k0,k1) = (formule#get_level (snd l0),formule#get_level (snd l1)) in
                    let (l_max,bet_max,l_min,bet_min) = if k0>k1 then (l0,b0,l1,b1) else (l1,b1,l0,b0) in
                    if ( fst l_max <> bet_max ) then 
                      ((b,v),l_min) 
                    else if ( fst l_min <> bet_min ) then
                      ((b,v),l_max)
                    else if k < formule#get_level (snd l_max) then
                      ((b,v),l_min) 
                    else
                      (l0,l1)
                 |(Some b0,None) ->
                    if (b0 <> fst l0 || formule#get_level (snd l0) > k) then
                      ((b,v),l1)
                    else
                      (l0,(b,v)) 
                 |(None,Some b1) ->
                    if (b1 <> fst l1 || formule#get_level (snd l1) > k) then
                      (l0,(b,v))
                    else
                      ((b,v),l1) 
                 |(None,None) -> 
                    ((b,v),l1)                
           end         
        | _ -> (l0,l1)
    in            
    formule#get_clauses#iter
      (fun (c:clause) ->
          let (l0,l1) = c#get_wl in
          let (l2,l3) = c#get_vneg#fold (replace_wl c false) (c#get_vpos#fold (replace_wl c true) (l0,l1)) in
            if not ((snd l0,snd l1)=(snd l2,snd l3) || (snd l0,snd l1)=(snd l3,snd l2)) then
              if (snd l2 = snd l0 || snd l2 = snd l1) then
                (formule#watch c l3 l1;
                formule#watch c l2 l0)
              else
                formule#watch c l2 l0;              
                formule#watch c l3 l1)


  (** Algo **)

  let algo (next_pari : Heuristic.t) cl n cnf = (* cl : activation du clause learning *)
  let nb_conf = ref 0 in (*********)

    let rec process formule etat first ((b,v) as lit) = (* effectue un pari et propage le plus loin possible *)
      try
        debug#p 2 "Setting %d to %B (level : %d)" v b (etat.level+1);
        let etat = make_bet formule lit etat in (* lève une exception si conflit créé *)
        match aux formule etat with (* lève erreur ici pour cl*)
          | Fine etat -> Fine etat
          | Backtrack etat when first -> (* ça arrive ça ?*)
              debug#p 2 "Backtrack : trying negation";
              let etat = undo formule etat in
              process formule etat false (neg lit)
          | Backtrack etat -> (* On a déjà fait le pari sur le littéral opposé, il faut remonter *)
              debug#p 2 "Backtrack : no options left, backtracking";
              Backtrack (undo formule etat) (* on fait sauter une deuxième tranche ? *)                 
      with 
        | Conflit (c,etat) ->
            nb_conf := 1+ !nb_conf ; (*********)
            stats#record "Conflits";
            debug#p 2 ~stops:true  "Impossible bet : clause %d false" c#get_id;
            (** ICI : graphe/dérivation en regardant la dernière tranche // update infos sur nb de conflits/restart/decision/vieillissement *)
            if (not cl) then (* clause learning ou pas *)
              begin
                let etat = undo formule etat in (* on fait sauter la tranche, qui contient tous les derniers paris *)
                if first then
                  process formule etat false (neg lit)
                else
                  Backtrack etat
              end
            else
              begin
                stats#start_timer "Clause learning (s)";
                let ((b,v),k,c_learnt) = conflict_analysis formule etat c in
                debug#p 2 "Learnt %a" c_learnt#print ();
                stats#stop_timer "Clause learning (s)";
                debug#p 2 "Reaching level %d to set %B %d (origin : learnt clause %d)" k b v c_learnt#get_id;
                let btck_etat = undo ~depth:(etat.level-k) formule etat in
                aux formule (continue_bet formule (b,v) c_learnt btck_etat)
              end
                
    and aux formule etat =
      debug#p 2 "Seeking next bet";
      stats#start_timer "Decisions (s)";
      let lit = next_pari (formule:>Formule.formule) in
      stats#stop_timer "Decisions (s)";
      (** ICI, tous les x conflits *)
      if (!nb_conf mod 1000 = 0) then (*********)
        begin
          stats#start_timer "Shaking (s)";(*********)        
          shake_up formule; (*********)
          stats#stop_timer "Shaking (s)"(*********)
        end;
      match lit with
        | None ->
            Fine etat (* plus rien à parier = c'est gagné *)
        | Some ((b,v) as lit) ->  
            stats#record "Paris";
            debug#p 2 "Next bet : %d %B" v b;
            process formule etat true lit in

    try
      let formule = init n cnf in
      let etat = { tranches = []; level = 0 } in
      match aux formule etat with
        | Fine etat -> Solvable (formule#get_paris)
        | Backtrack _ -> Unsolvable
    with Unsat -> Unsolvable (* Le prétraitement à détecté un conflit, ou Clause learning est unsat*)

end






