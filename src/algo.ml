open Clause
open Formule
open Debug
open Answer
open Interaction
open Algo_base

type 'a result = Fine of 'a | Backtrack of 'a

type t = Heuristic.t -> bool -> int -> int list list -> Answer.t

let neg : literal -> literal = function (b,v) -> (not b, v)

exception Conflit of (clause*etat)

module Bind = functor(Base : Algo_base) ->
struct

  include Base

  let decrease_level etat = { etat with level = etat.level-1 }

  let increase_level etat = { etat with level = etat.level+1 }

  (* Parie sur (b,v) puis propage. Pose la dernière tranche qui en résulte, quoiqu'il arrive *)
  let make_bet (formule:formule) (b,v) etat =
    let etat = increase_level etat in (* on augmente le level *)
    let lvl = etat.level in 
    begin
      try
        formule#set_val b v lvl (* on fait le pari *)
      with 
          Empty_clause c -> (* conflit suite à pari *)
            raise (Conflit (c,{ etat with tranches = ((b,v),[])::etat.tranches } )) (* on prend soin d'empiler la dernière tranche *)
    end;
    try 
      let propagation = constraint_propagation formule (b,v) etat [] in (* on propage *)
      { etat with tranches = ((b,v),propagation)::etat.tranches } (* on renvoie l'état avec la dernière tranche ajoutée *)
    with
        Conflit_prop (c,acc) -> (* conflit dans la propagation *)
          raise (Conflit (c,{ etat with tranches = ((b,v),acc)::etat.tranches } ))

  (* Compléte la dernière tranche, assigne (b,v) (ce n'est pas un pari) puis propage. c_learnt : clause apprise ayant provoqué le bactrack qui a appelé continue_bet *)
  let continue_bet (formule:formule) (b,v) c_learnt etat = 
    let lvl=etat.level in
    if lvl=0 then (* niveau 0 : tout conflit indiquerait que la formule est non sat *)
      try
        formule#set_val b v lvl; (* peut lever Empty_clause *)
        let _ = constraint_propagation formule (b,v) etat [] in (* peut lever Conflit_prop *)
        etat
      with _ -> raise Unsat (** TRES IMPORTANT : c'est ici que le clause learning détecte que la formule est insatisfiable *)
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
              let continue_propagation = constraint_propagation formule (b,v) etat ((b,v)::propagation) in (* on poursuit l'assignation sur la dernière tranche *)
              { etat with tranches = (pari,continue_propagation)::q }
            with
                Conflit_prop (c,acc) -> 
                  raise (Conflit (c,{ etat with tranches = (pari,acc)::q } ))

  let undo_assignation formule (_,v) = formule#reset_val v

  (* annule les depth dernières tranches *)
  let undo ?(depth=1) (formule:formule) etat = 
    stats#start_timer "Bactrack (s)";
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
                aux (depth-1) (decrease_level { etat with tranches = q }) (* on n'oublie pas de diminuer le level à chaque fois *)
              end
    in
      let res = aux depth etat in
      stats#stop_timer "Bactrack (s)";
      res
      
  (** Conflict analysis *)

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
      | (pari,propagation)::q ->
          match propagation with
            | [] -> pari
            | (b,v)::t -> (b,v)
          
(* conflit déclenché en pariant le littéral de haut de tranche, dans la clause c
   en résultat : (l,k,c) où : 
      - l : littéral de + haut niveau dans la clause apprise
      - k : niveau auquel backtracker
      - c : clause apprise
*)
  let conflict_analysis (formule:formule) etat c =
    let c_learnt = formule#new_clause in
    c_learnt#union c; (* initialement, la clause à apprendre est la clause où est apparu le conflit *)
    let rec aux (pari,propagation) = 
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
                    aux (pari,q)
            end
        | Some l -> (* la clause peut être apprise : elle ne contient plus qu'un seul littéral du niveau max *)
            begin
              let (bt_lvl,sgt) = backtrack_level formule etat c_learnt in
              begin
                match sgt with (* None si singleton ! *)
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
        let etat = make_bet formule lit etat in (* fait un pari et propage, lève une exception si conflit créé *)
        match aux formule etat with (* on essaye de prolonger l'assignation courante avec d'autres paris *)
          | Fine etat -> Fine etat
          | Backtrack etat when first -> (* retourner la pièce *)
              debug#p 2 "Backtrack : trying negation";
              let etat = undo formule etat in
              process formule etat false (neg lit)
          | Backtrack etat -> (* On a déjà fait le pari sur le littéral opposé, il faut remonter *)
              debug#p 2 "Backtrack : no options left, backtracking";
              Backtrack (undo formule etat)
      with 
        | Conflit (c,etat) ->
            nb_conf := 1+ !nb_conf ; (*********)
            stats#record "Conflits";
            debug#p 2 ~stops:true "Impossible bet : clause %d false" c#get_id;
            let file = open_out "example.dot" in
            Printf.fprintf file "%a%!" (print_graph (formule:>Formule.formule) (List.hd etat.tranches) etat.level) c;
            close_out file;
            (** ICI : graphe/dérivation en regardant la dernière tranche // update infos sur nb de conflits/restart/decision/vieillissement *)
            if (not cl) then (* clause learning ou pas *)
              begin
                let etat = undo formule etat in (* on fait sauter la tranche, qui contient tous les derniers paris *)
                if first then
                  process formule etat false (neg lit) (* on essaye de retourner la pièce *)
                else
                  Backtrack etat (* sinon on bactrack *)
              end
            else (* du clause learning *)
              begin
                stats#start_timer "Clause learning (s)";
                let ((b,v),k,c_learnt) = conflict_analysis formule etat c in
                debug#p 2 "Learnt %a" c_learnt#print ();
                stats#stop_timer "Clause learning (s)";
                debug#p 2 "Reaching level %d to set %B %d (origin : learnt clause %d)" k b v c_learnt#get_id;
                let btck_etat = undo ~depth:(etat.level-k) formule etat in (* bactrack non chronologique <--- c'est ici que le clause learning bactrack *)
                aux formule (continue_bet formule (b,v) c_learnt btck_etat) (* on poursuit *)
              end
                
    and aux formule etat =
      debug#p 2 "Seeking next bet";
      stats#start_timer "Decisions (s)";
      let lit = next_pari (formule:>Formule.formule) in (* choisir un littéral sur lequel parier *)
      stats#stop_timer "Decisions (s)";
      (***********)
      (*if (!nb_conf mod 10000 = 0) then
        begin
          stats#start_timer "Shaking (s)";
          shake_up formule;
          stats#stop_timer "Shaking (s)"
        end;*)
      match lit with
        | None ->
            Fine etat (* plus rien à parier = c'est gagné *)
        | Some ((b,v) as lit) ->  
            stats#record "Paris";
            debug#p 2 "Next bet : %d %B" v b;
            process formule etat true lit in (* on assigne (b,v) et on propage *)

    try
      let formule = init n cnf in
      let etat = { tranches = []; level = 0 } in
      match aux formule etat with
        | Fine etat -> Solvable (formule#get_paris)
        | Backtrack _ -> Unsolvable
    with Unsat -> Unsolvable (* Le prétraitement à détecté un conflit, _ou_ Clause learning a levé cette erreur car formule unsat *)

end






