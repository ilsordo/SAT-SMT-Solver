open Clause
open Formule
open Debug
open Interaction
open Algo_base
open Conflict_analysis

exception End_analysis of (literal option*literal list*literal list)

let neg : literal -> literal = function (b,v) -> (not b, v)

let (@) l1 l2 = List.(rev_append (rev l1) l2)

exception Conflit of (clause*etat)

type dpll_answer = 
  | No_bet of bool vartable * (literal list -> (literal list*(unit -> dpll_answer)))
  | Bet_done of literal list * (unit -> dpll_answer) * (literal list -> (literal list*(unit -> dpll_answer)))
  | Conflit_dpll of literal list * (unit -> dpll_answer)


module type Algo_parametric =
sig
  val run : Heuristic.t -> bool -> bool -> bool -> int -> literal list list -> (literal list*(unit -> dpll_answer))
end

module Bind = functor(Base : Algo_base) ->
struct

  (** Bet and set *)

  (* Parie sur (b,v) puis propage. Pose la dernière tranche qui en résulte, quoiqu'il arrive *)
  let make_bet (b,v) first pure_prop (formule:Base.formule) etat =
    let etat = { etat with level = etat.level + 1 } in
    let lvl = etat.level in 
    begin
      try
        formule#set_val b v lvl (* on fait le pari *)
      with 
          Empty_clause c -> (* conflit suite à pari *)
            raise (Conflit (c,{etat with tranches = (first,(b,v),[])::etat.tranches } )) (* on prend soin d'empiler la dernière tranche *)
    end;
    try 
      let propagation = Base.constraint_propagation pure_prop formule (b,v) etat [] in (* on propage *) (** ne pas mettre (b,v) dans [] *)
      ({ etat with tranches = (first,(b,v),propagation)::etat.tranches }, propagation@[(b,v)]) (***) (* on renvoie l'état avec les dernières assignations effectuées *)
    with
        Conflit_prop (c,acc) -> (* conflit dans la propagation *)
          raise (Conflit (c,{etat with tranches = (first,(b,v),acc)::etat.tranches } ))

  (* Compléte la dernière tranche, assigne (b,v) (ce n'est pas un pari) puis propage. c_learnt : clause apprise ayant provoqué le backtrack qui a appelé continue_bet *)
  let continue_bet (b,v) ?cl pure_prop (formule:Base.formule) etat = (* cl : on sait de quelle clause vient l'assignation de (b,v) *)
    let lvl=etat.level in
    if lvl=0 then (* niveau 0 : tout conflit indiquerait que la formule est non sat *)
      try
        formule#set_val b v lvl; (* peut lever Empty_clause *)
        let continue_propagation = Base.constraint_propagation pure_prop formule (b,v) etat [(b,v)] in (* peut lever Conflit_prop *) (** prq [(b,v)] >> pour continue_propagation *)
        (etat, continue_propagation)
      with  
        | Empty_clause _ | Conflit_prop _ -> raise Unsat (** Ici : le clause learning détecte que la formule est insatisfiable *)
    else    
      match etat.tranches with
        | [] -> assert false 
        | (first,pari,propagation)::q ->
            begin
              try
                formule#set_val b v ?cl lvl (* Subtilité de syntaxe : si cl est None, l'argument est omis sinon il est passé *) (***)
              with 
                  Empty_clause c -> 
                    raise (Conflit (c,{ etat with tranches = (first,pari,(b,v)::propagation)::q } ))
            end;
            try 
              let continue_propagation = Base.constraint_propagation pure_prop formule (b,v) etat [(b,v)] in (** pas sur pour les 5 lignes suivantes *)
              let propagation = continue_propagation@propagation in (* on poursuit l'assignation sur la dernière tranche *)
              ({ etat with tranches = (first,pari,propagation)::q }, continue_propagation) 
            with
                Conflit_prop (c,acc) -> 
                  raise (Conflit (c,{ etat with tranches = (first,pari,acc@propagation)::q } ))
  
  
  (** Undo *)
  
  (* tous les lit de la clause sont faux car c'est une clause à conflit *)
  let undo_clause formule etat (c:clause) = (* on est déjà au bon niveau, on sait que 2 lit aux moins de ce niveaux sont dans la clause *)
    let rec aux seen to_rem to_keep = 
      match to_keep with
        | [] -> (seen,to_rem,[])
        | (b,v)::q ->
            if (c#mem_all (not b) v) then
              begin
                match seen with
                  | None -> 
                      formule#reset_val v;
                      aux (Some (not b,v)) ((b,v)::to_rem) q
                  | Some (b0,v0) -> 
                    raise (End_analysis (seen,to_rem,to_keep))
              end
            else    
              (if (c#mem_all b v) then assert false;
              formule#reset_val v;
              aux seen ((b,v)::to_rem) q) in
    match etat.tranches with 
      | [] -> raise Unsat (********* un des unsat du smt ??? **)
      | (first,(b,v),propagation)::q ->
           try
             begin
               match aux None [] propagation with
                 | (None,to_rem,to_keep) -> assert false
                 | (Some l,to_rem,to_keep) ->
                     begin 
                       assert ((c#mem_all (not b) v) && to_keep = []);
                       Base.set_wls formule c (b,v) l;  (************)
                       (l,{etat with tranches = (first,(b,v),[])::q},to_rem)
                     end
             end
           with  
             | End_analysis (seen,to_rem,to_keep) ->  
                 begin
                   match seen with
                     | None -> assert false
                     | Some l -> 
                         begin
                          Base.set_wls formule c (b,v) l;  (************)
                          (l,{etat with tranches = (first,(b,v),to_keep)::q},to_rem)
                         end
                 end
                 
  
  
  let undo_tranche formule etat = 
    let undo_assignation formule (_,v) = formule#reset_val v in
      match etat.tranches with (* annule la dernière tranche et la fait sauter *)
        | [] -> assert false
        | (first,pari,propagation)::q ->
            List.iter (undo_assignation formule) propagation;
            undo_assignation formule pari;
            ({ level = etat.level - 1; tranches = q }, pari::(List.rev propagation)) (** plus récent en tête ?*)
  
  (*
  undo : 
    fait sauter des tranches jusqu'à atteindre la condition d'arrêt
    renvoie les listes des littéraux qu'il a fait sauter
    renvoie le prochain littéral sur lequel parier
    renvoie l'état
  *)
  let undo policy (formule:Base.formule) etat = 
    let rec concat acc = function
      | [] -> acc
      | t::q -> concat (List.rev_append t acc) q in
    let rec aux policy etat acc =
      match policy with
        | First -> 
            begin
              match etat.tranches with (* annule la dernière tranche et la fait sauter *)
                | [] -> raise Unsat (** Ici le non clause learning détecte formule insatisfiable *)
                | (first,pari,propagation)::q ->
                    let (etat,prop) = undo_tranche formule etat in
                    if first then
                      (neg pari,etat,concat [] (prop::acc)) (***)
                    else
                      aux policy etat (prop::acc) (***)
            end
        | Var_depth (k,l) -> 
            if k=0 then
              (l,etat,concat [] acc) (** Est-ce correct? (j'ai enlevé un prop pas défini)*)
            else
              let (etat,prop) = undo_tranche formule etat in
              aux (Var_depth(k-1,l)) etat (prop::acc) (* on n'oublie pas de diminuer le level à chaque fois *) 
        | Clause_depth (k,c) ->                
            if k=0 then
              let (l,etat,prop) = undo_clause formule etat c in
                (l,etat,concat [] (prop::acc)) (***)
            else
              let (etat,prop) = undo_tranche formule etat in
              aux (Clause_depth(k-1,c)) etat (prop::acc) (* on n'oublie pas de diminuer le level à chaque fois *)                      
    in
    stats#start_timer "Backtrack (s)";
    let res = aux policy etat [] in
    stats#stop_timer "Backtrack (s)";
    res
   
   
  (** Algo **)

  let run (next_pari : Heuristic.t) cl interaction pure_prop n cnf = (* cl : activation du clause learning *)
    let repl = new repl (Some 1) in
    
    let rec process formule etat progress () = (* effectue un pari et propage le plus loin possible *)
      try
        (*debug#p 2 "Setting %d to %B (level : %d)" v b (etat.level+1);*)
        let (etat,assignations) = progress formule etat in (* fait un pari et propage, lève une exception si conflit créé *) (* true = first *)
        Bet_done (assignations,bet formule etat,backtrack formule etat) (* on essaye de prolonger l'assignation courante avec d'autres paris *)
      with 
        | Conflit (c,etat) ->
            stats#record "Conflits";
            debug#p 2 ~stops:true "Impossible bet : clause %d false" c#get_id;
            if interaction && repl#is_ready then
              repl#start (formule:>Formule.formule) etat c stdout;
            if (not cl) then (* pas de clause learning *)
              let (l, etat,undo_list) = undo First formule etat in (* on fait sauter la tranche, qui contient tous les derniers paris *) (** ICI : Unsat du non cl *)
              Conflit_dpll (undo_list, process formule etat (continue_bet l pure_prop)) (***) (* on essaye de retourner la plus haute pièce possible *) 
            else (* clause learning *)
              begin
                stats#start_timer "Clause learning (s)";
                let ((b,v),k,c_learnt) = conflict_analysis Base.set_wls formule etat c in
                debug#p 2 "Learnt %a" c_learnt#print ();
                stats#stop_timer "Clause learning (s)";
                debug#p 2 "Reaching level %d to set %B %d (origin : learnt clause %d)" k b v c_learnt#get_id;
                let (l,etat,undo_list) = undo (Var_depth(etat.level-k,(b,v))) formule etat in (* backtrack non chronologique <--- ici clause learning backtrack *)
                Conflit_dpll (undo_list,process formule etat (continue_bet l ~cl:c_learnt pure_prop)) (***) (* on poursuit *) (** ICI : Unsat du cl *)
              end
                
    and bet formule etat () =
      debug#p 2 "Seeking next bet";
      stats#start_timer "Decisions (s)";
      let lit = next_pari (formule:>Formule.formule) in (* choisir un littéral sur lequel parier *)
      stats#stop_timer "Decisions (s)";
      match lit with
        | None ->
            No_bet (formule#get_paris,backtrack formule etat) (* plus rien à parier = c'est gagné *)
        | Some ((b,v) as lit) ->  
            stats#record "Paris";
            debug#p 2 "Next bet : %d %B" v b;
            process formule etat (make_bet lit true pure_prop) () (* on assigne (b,v) et on propage *)
              
    and backtrack formule etat clause = (***)
      let c = formule#new_clause clause in
      let (l,etat,undo_list) = undo (learn_clause Base.set_wls formule etat c) formule etat in
      (undo_list,process formule etat (continue_bet l ~cl:c pure_prop))
        
    in 
    try
      let (formule,prop_init) = Base.init n cnf pure_prop in
      let etat = { tranches = []; level = 0 } in
      (prop_init, bet formule etat)
    with Unsat -> raise Unsat (* Le prétraitement à détecté un conflit, _ou_ Clause learning a levé cette erreur car formule unsat *) (***)

end
