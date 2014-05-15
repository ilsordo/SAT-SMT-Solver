open Clause
open Formule
open Debug
open Answer
open Interaction
open Algo_base
open Conflict_analysis

type t = Heuristic.t -> bool -> bool -> int -> int list list -> Answer.t

let neg : literal -> literal = function (b,v) -> (not b, v)

exception Conflit of (clause*etat)

module Bind = functor(Base : Algo_base) ->
struct

  open Base

  (* Parie sur (b,v) puis propage. Pose la dernière tranche qui en résulte, quoiqu'il arrive *)
  let make_bet (formule:formule) (b,v) first etat =
    let level = etat.lvl in 
    begin
      try
        formule#set_val b v lvl (* on fait le pari *)
      with 
          Empty_clause c -> (* conflit suite à pari *)
            raise (Conflit (c,{ etat with level = lvl + 1; tranches = (first,(b,v),[])::etat.tranches } )) (* on prend soin d'empiler la dernière tranche *)
    end;
    try 
      let propagation = constraint_propagation formule (b,v) etat [] in (* on propage *)
      { etat with level = lvl + 1; tranches = (first,(b,v),propagation)::etat.tranches } (* on renvoie l'état avec la dernière tranche ajoutée *)
    with
        Conflit_prop (c,acc) -> (* conflit dans la propagation *)
          raise (Conflit (c,{ etat with level = lvl + 1; tranches = (first,(b,v),acc)::etat.tranches } ))

  (* Compléte la dernière tranche, assigne (b,v) (ce n'est pas un pari) puis propage. c_learnt : clause apprise ayant provoqué le backtrack qui a appelé continue_bet *)
  let continue_bet (formule:formule) (b,v) c_learnt etat = 
    let lvl=etat.level in
    if lvl=0 then (* niveau 0 : tout conflit indiquerait que la formule est non sat *)
      try
        formule#set_val b v lvl; (* peut lever Empty_clause *)
        let _ = constraint_propagation formule (b,v) etat [] in (* peut lever Conflit_prop *)
        etat
      with 
        | Empty_clause | Conflit_prop -> raise Unsat (** Ici : le clause learning détecte que la formule est insatisfiable *)
    else    
      match etat.tranches with
        | [] -> assert false 
        | (first,pari,propagation)::q ->
            begin
              try
                formule#set_val b v ~cl:c_learnt lvl
              with 
                  Empty_clause c -> 
                    raise (Conflit (c,{ etat with level = lvl + 1; tranches = (first,pari,(b,v)::propagation)::q } ))
            end;
            try 
              let continue_propagation = constraint_propagation formule (b,v) etat ((b,v)::propagation) in (* on poursuit l'assignation sur la dernière tranche *)
              { etat with level = level + 1; tranches = (first,pari,continue_propagation)::q }
            with
                Conflit_prop (c,acc) -> 
                  raise (Conflit (c,{ etat with level = level + 1; tranches = (first,pari,acc)::q } ))
  
  let undo_tranche formule etat = 
    let undo_assignation formule (_,v) = formule#reset_val v in
      match etat.tranches with (* annule la dernière tranche et la fait sauter *)
        | [] -> assert false
        | (first,pari,propagation)::q ->
            List.iter (undo_assignation formule) propagation;
            undo_assignation formule pari;
            { etat with level = etat.level - 1; tranches = q } (** maintenant le niveau est diminué ici *)
  
  let undo depth (formule:formule) etat = 
    let rec aux dpth etat =
      match dpth with
        | None -> 
            begin
              match etat.tranches with (* annule la dernière tranche et la fait sauter *)
                | [] -> raise Unsat (** Ici le non clause learning détecte formule insatisfiable *)
                | (first,pari,_)::q ->
                    let etat = undo_tranche formule etat in
                    if first then
                      (Some (neg pari),etat)
                    else
                      aux dpth etat
            end
        | Some k ->
            if k=0 then
              (None,etat)
            else
              aux (Some (k-1)) (undo_tranche formule etat) (* on n'oublie pas de diminuer le level à chaque fois *)
    in
      stats#start_timer "Backtrack (s)";
      let res = aux depth etat in
      stats#stop_timer "Backtrack (s)";
      res
      

  (** Algo **)

  let run (next_pari : Heuristic.t) cl interaction n cnf = (* cl : activation du clause learning *)
    let repl = new repl (Some 1) in

    let rec process formule etat first ((b,v) as lit) = (* effectue un pari et propage le plus loin possible *)
      try
        debug#p 2 "Setting %d to %B (level : %d)" v b (etat.level+1);
        let etat = make_bet formule lit first etat in (* fait un pari et propage, lève une exception si conflit créé *)
          bet formule etat (* on essaye de prolonger l'assignation courante avec d'autres paris *)
      with 
        | Conflit (c,etat) ->
            stats#record "Conflits";
            debug#p 2 ~stops:true "Impossible bet : clause %d false" c#get_id;
            if interaction && repl#is_ready then
              repl#start (formule:>Formule.formule) etat c stdout;
            if (not cl) then (* pas de clause learning *)
              match undo None formule etat with (* on fait sauter la tranche, qui contient tous les derniers paris *) (** ICI : Unsat du non cl *)
                | (None,_) -> assert false (* on ne sais pas quelle pièce retourner *)
                | (Some l, etat) -> process formule etat false l (* on essaye de retourner la plus haute pièce possible *) 
            else (* du clause learning *)
              begin
                stats#start_timer "Clause learning (s)";
                let ((b,v),k,c_learnt) = conflict_analysis formule etat c in
                debug#p 2 "Learnt %a" c_learnt#print ();
                stats#stop_timer "Clause learning (s)";
                debug#p 2 "Reaching level %d to set %B %d (origin : learnt clause %d)" k b v c_learnt#get_id;
                let (_,btck_etat) = undo (Some (etat.level-k)) formule etat in (* backtrack non chronologique <--- c'est ici que le clause learning backtrack *)
                bet formule (continue_bet formule (b,v) c_learnt btck_etat) (* on poursuit *) (** ICI : Unsat du cl *)
              end
                
    and bet formule etat =
      debug#p 2 "Seeking next bet";
      stats#start_timer "Decisions (s)";
      let lit = next_pari (formule:>Formule.formule) in (* choisir un littéral sur lequel parier *)
      stats#stop_timer "Decisions (s)";
      match lit with
        | None ->
            Solvable (formule#get_paris) (* plus rien à parier = c'est gagné *)
        | Some ((b,v) as lit) ->  
            stats#record "Paris";
            debug#p 2 "Next bet : %d %B" v b;
            process formule etat true lit in (* on assigne (b,v) et on propage *)

    try
      let formule = init n cnf in
      let etat = { tranches = []; level = 0 } in
        bet formule etat
    with Unsat -> Unsolvable (* Le prétraitement à détecté un conflit, _ou_ Clause learning a levé cette erreur car formule unsat *)

end






