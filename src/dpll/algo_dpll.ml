open Algo
open Clause
open Debug
open Formule_dpll
open Formule

type etat = { formule : formule_dpll; tranches : tranche list } (*** ajouter lvl courant *)

let name = "Dpll"



(***)

let init n cnf =
  let f = new formule_dpll in
  f#init n cnf;
  if f#check_empty_clause then
    let _ = constraint_propagation f [] in
    { formule = f; tranches = [] }
  else
    raise Init_empty (* modifier check_empty pour lever un conflit dès ci-dessus ? *)


let undo_assignation formule (_,v) = formule#reset_val v


let undo etat ?(cl=None) =
  let undo_tranche etat = match etat.tranches with (* annule la dernière tranche et la fait sauter *)
    | [] -> assert false 
    | (pari,propagation)::q ->
        List.iter (undo_assignation etat.formule) propagation;
        undo_assignation etat.formule pari;
        { etat with tranches = q } in
  let etat = undo_tranche etat in (* on enlève forcèment la première tranche (contient 1 et 1 seul lit de c_learnt) *)
  if cl = Some c_learnt then
    let rec aux etat = match etat.tranches with 
      | [] -> assert false
      | (pari,propagation)::q ->
          if List.exists (fun (b,v) -> c_learnt#mem_cl b v) (pari::propagation) then (** travailler sur littéraux ou var ? mem_cl ? *)
            etat
          else
            aux (undo_tranche etat)
    in aux etat
  else
    etat


let get_formule { formule = formule ; _ } = (formule:>formule)

(***)


let rec constraint_propagation formule acc ?(cl=false) = 
  match formule#find_singleton with 
    | None ->
        begin
          match formule#find_single_polarite with
            | None -> acc
            | Some ((b,v),c) ->   
                try
                  debug#p 3 "Propagation : single polarity found : %d %B" v b;
                  debug#p 4 "Propagation : setting %d to %B" v b;
                  if cl then
                    formule#set_val b v c (***)
                  else
                    formule#set_val b v; 
                  aux ((b,v)::acc) 
                with                 
                  Clause_vide (l,c) -> raise (Conflit_prop (l,c,(b,v)::acc)) 
        end
    | Some ((b,v),c) ->
        try
          debug#p 3 "Propagation : singleton found : %d %B" v b;
          debug#p 4 "Propagation : setting %d to %B" v b;
          if cl then
            formule#set_val b v c (***)
          else
            formule#set_val b v;
          aux ((b,v)::acc)
        with
          Clause_vide (l,c) -> raise (Conflit_prop (l,c,(b,v)::acc))  in


(* pari puis propage
   pose la dernière tranche, quoiqu'il arrive
   renvoie l'etat si pas de conflit
           Conflit_cl (l,c,etat) si conflit
*)
let make_bet (b,v) etat ?(cl=false) lvl =
  begin
    try
      etat.formule#set_val b v lvl
    with 
      Clause_vide (l,c) -> 
        raise (Conflit (l,c,{ etat with tranches = ((b,v),[])::etat.tranches } ))(* On a créé une clause vide en faisant le pari *)
  end;
  try 
    let propagation = constraint_propagation etat.formule [] cl in
      { etat with tranches = ((b,v),propagation)::etat.tranches }
  with
    Conflit_prop (l,c,acc) -> 
      raise (Conflit (l,c,{ etat with tranches = ((b,v),acc)::etat.tranches } ))

let continue_bet (b,v) etat lvl = match etat.tranches with (* on complète la dernière tranche *)
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
    
    
let max_level c lvl = (* None si plusieurs du niveau max, Some (b,v) si un seul *)
  let aux b v (lvl,vs) =
    if (etat.formule#get_level v) = lvl then
      (lvl,None)
    else if (etat.formule#get_level v) > lvl then
      (etat.formule#get_level v, Some (b,v)
    else
      (lvl,vs) in
  c#get_vpos#fold aux true (c#get_vpos#fold aux false (0,None))  

let snd_level c = 
  
(* conflit déclenché en pariant b sur v dans la clause c
     on va travailler sur la dernière tranche d'assignations
     il faut que cette tranche contienne le littéral ayant provoqué le conflit en haut de tranche (et que ce littéral ait été caché là où il faut ?)
     fait-on suffisament attention à la distinction littéral/variable ?
     on remonte la tranche pour créer la clause à apprendre
     on enregistre la clause apprise dans la formule (en copiant les visibilités actuels)
     on renvoie la clause apprise  
*)
let conflict_analysis etat c lvl = 
  let c_learnt = (etat.formule#new_clause) in
  let rec aux (pari,propagation) = match max_level c_learnt with
    | None ->
        match propagation with
          | [] -> c_learnt#union c (snd pari)
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
    | Some (b,v) -> ((b,v),c_learnt) (*** RESULT *)
    
    
    
    
