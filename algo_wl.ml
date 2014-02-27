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
      List.iter (fun v -> formule#get_paris#remove v) !l; (* on annule toutes les assignations depuis le dernier pari *)
      raise Wl_fail (***)
    end
  else
    begin
      l := (var::(!l)); (* se rappeler que v subit une assignation (et si v était déjà assigné et subit pari non contradictoire ? impossible ? *)
      formule#get_paris#set var b (* on fait l'assignation sans risque *)
    end;

  let deplacer = (*il faut deplacer des jumelles *)
    if b then
      formule#get_wl_neg var 
    else
      formule#get_wl_pos var in
  deplacer#iter (fun c -> match formule#update_clause c (not b,var) with
    | WL_Conflit ->     
        List.iter (fun var -> formule#get_paris#remove var) !l; (* on annule toutes les assignations depuis le dernier pari *)
        raise Wl_fail
    | WL_New -> ()
    | WL_Assign (b,v) -> let _ = constraint_propagation formule v b l in () (*** suspect *)
    | WL_Nothing -> ()  );
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
                List.iter (fun var -> formule#get_paris#remove var) l; (* on annule les assignations *)
                try 
                  let ll=constraint_propagation formule var false (ref []) in (* on a encore une chance sur le faux *)
                  if aux () then (* si on réussit à poursuivre l'assignation jusqu'au bout *)
                    true (* c'est gagné *)
                  else
                    begin
                      List.iter (fun var -> formule#get_paris#remove var) ll;
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
                      List.iter (fun var -> formule#get_paris#remove var) ll;
                      false
                    end   
                with
                  | Wl_fail -> false
  in

  try
    formule#init n cnf; (* on a prétraité, peut être des clauses vides créées et à détecter au plus tôt *)
    formule#check_empty_clause;
    formule#init_wl; (* Les jumelles sont posées *)
    (* à partir de maintenant : pas de clauses vides, singleton ou tautologie. De plus, un ensemble de var a été assigné (avec clauses cachées) sans conflits. Ces vars n'apparaissent nul part ailleur dorénavant *) 
    if aux () then 
      Solvable formule#get_paris
    else 
      Unsolvable
  with
    | Clause_vide -> Unsolvable (* Clause vide dès le début *)







