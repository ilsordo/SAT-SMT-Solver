open Formule
open Formule_wl
open Clause
open Debug
open Answer


exception Wl_fail

let print_valeur p v = function
  | true -> Printf.fprintf p "v %d\n" v
  | false -> Printf.fprintf p "v -%d\n" v

let print_answer p = function
  | Unsolvable -> Printf.fprintf p "s UNSATISFIABLE\n"
  | Solvable valeurs -> 
      Printf.fprintf p "s SATISFIABLE\n";
      valeurs#iter (print_valeur p)


(***************************************************)

let next_pari formule = (* Some v si on doit faire le prochain pari sur v, None si tout a été parié *)
  let n=formule#get_nb_vars in
  let rec parcours_paris = function
    | 0 -> None
    | m -> 
        if (formule#get_pari m != None) then 
          parcours_paris (m-1) 
        else 
          Some m in
  parcours_paris n


(* constraint_propagation reçoie un ordre d'assignation
      la fonction doit faire cette assignation et toutes celles qui en découlent, ssi pas de conflits créées
      si conflits, aucune assignation ne doit être faite
      si réussit : renvoie la liste des assignations effectuées
*)
(* l : liste des assignations effectuées depuis le dernier pari, inclu *)
let rec constraint_propagation formule var b l =

  if ((formule#get_paris#find var) = Some (not b)) then (* double paris contradictoire (y a-t-il un pb si double paris non contradictoire ?)  *)
    begin
      debug 1 "Tentative assignation contradictoire sur variable %d " var ;
      List.iter (fun v -> debug 1 "Assignation annulé sur variable %d " v ; formule#get_paris#remove v) !l; (* on annule toutes les assignations depuis le dernier pari *)
      raise Wl_fail (***)
    end
  else
    begin
      debug 1 "Assignation %B sur variable %d " b var ;
      l := (var::(!l)); (* se rappeler que v subit une assignation (et si v était déjà assigné et subit pari non contradictoire ? impossible ? *)
      formule#get_paris#set var b (* on fait l'assignation sans risque *)
    end;

  let deplacer = (*il faut deplacer des jumelles *)
    if b then
      formule#get_wl_neg var 
    else
      formule#get_wl_pos var in
  deplacer#iter (fun c -> match formule#update_clause c (not b,var) with
    | WL_Conflit -> debug 1 "Jumelles bloquée sur false (traitement de variable %d assignée a %B) " var b ;
        List.iter (fun var -> debug 1 "Assignation annulé sur variable %d " var ; formule#get_paris#remove var) !l; (* on annule toutes les assignations depuis le dernier pari *)
        raise Wl_fail
    | WL_New -> debug 1 "Jumelles déplacées (traitement de variable %d assignée a %B) " var b ;
    | WL_Assign (bb,v) -> debug 1 "Jumelles demande assignement %B sur variable %d (traitement de variable %d assignée a %B) " bb v var b ;let _ = constraint_propagation formule v bb l in () (*** suspect *)
    | WL_Nothing -> debug 1 "Jumelles immobiles sans problème (traitement de variable %d assignée a %B) " var b ; ()  );
  !l (* on renvoie toutes les assignations effectuées *)




let algo n cnf =
  let formule = new formule_wl in

  let rec aux()=
    match next_pari formule with
      | None -> true (* plus rien à parier = c'est gagné *)
      | Some var ->  
          try 
            let l = constraint_propagation formule var true (ref []) in (* première chance en pariant vrai *)
            if aux () then (* si on réussit à poursuivre l'assignation jusqu'au bout *)
              true (* c'est gagné *)
            else (* pb plus loin dans le backtracking, il faut tout annuler pour parier sur faux *)
              begin
                List.iter (fun var -> debug 1 "Assignation annulé sur variable %d " var ; formule#get_paris#remove var) l; (* on annule les assignations *)
                try 
                  let ll=constraint_propagation formule var false (ref []) in (* on a encore une chance sur le faux *)
                  if aux () then (* si on réussit à poursuivre l'assignation jusqu'au bout *)
                    true (* c'est gagné *)
                  else
                    begin
                      List.iter (fun var -> debug 1 "Assignation annulé sur variable %d " var ; formule#get_paris#remove var) ll;
                      false
                    end   
                with
                  | Wl_fail -> false
              end
          with
            | Wl_fail ->   
                try 
                  let ll=constraint_propagation formule var false (ref []) in (* on a encore une chance sur le faux *)
                  if aux () then (* si on réussit à poursuivre l'assignation jusqu'au bout *)
                    true (* c'est gagné *)
                  else
                    begin
                      List.iter (fun var -> debug 1 "Assignation annulé sur variable %d " var ; formule#get_paris#remove var) ll;
                      false
                    end   
                with
                  | Wl_fail -> false
  in

  try
    formule#init n cnf; (* on a prétraité, peut être des clauses vides créées et à détecter au plus tôt *)
    formule#check_empty_clause;
    formule#init_wl;
    (* à partir de maintenant : pas de clauses vides, singleton ou tautologie. De plus, un ensemble de var a été assigné (avec clauses cachées) sans conflits. Ces vars n'apparaissent nul part ailleur dorénavant *) 
    if aux () then 
      Solvable formule#get_paris
    else 
      Unsolvable
  with
    | Clause_vide -> Unsolvable (* Clause vide dès le début *)







