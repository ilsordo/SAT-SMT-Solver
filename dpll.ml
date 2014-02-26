open Clause
open Formule
open Clause

type answer = Unsolvable | Solvable of bool vartable

type propagation_result = Fine of variable list | Conflict (* C'est juste pour la lisibilité du code, si tu aimes pas on peut le virer *)

let print_valeur p v = function
  | true -> Printf.fprintf p "v %d\n" v
  | false -> Printf.fprintf p "v -%d\n" v

let print_answer p = function
  | Unsolvable -> Printf.fprintf p "s UNSATISFIABLE\n"
  | Solvable valeurs -> 
      Printf.fprintf p "s SATISFIABLE\n";
      valeurs#iter (print_valeur p)



(*************)

let next_pari formule = (* Some v si on doit faire le prochain pari sur v, None si tout a été parié (et on a donc une affectation gagnante) *)
  let n=formule#get_nb_vars in
  let rec parcours_paris = function
    | 0 -> None
    | m -> 
        if (formule#get_pari m != None) then 
          parcours_paris (m-1) 
        else 
          Some m in
  parcours_paris n

let constraint_propagation formule = (* on affecte v et on propage, on renvoie la liste des variables affectées + Conflict si une clause vide a été générée, Fine sinon*)
  let var_add = ref [] in (* var_add va contenir la liste des variables ayant été affectées *)
  let stop = ref false in (* stop = false : il y a encore à propager, stop = true : on a fini de propager *)
  let affect v b =
    Printf.eprintf "Setting %d to %b\n" v b;
    var_add := v::(!var_add);
    formule#set_val b v in (* Peut lever une exception qui est attrapée plus loin *)
  try
    while not (!stop) do
      begin
        match formule#find_singleton with (* toute les variables qui forment des clauses singletons *)
          | None ->
              Printf.eprintf "Pas de singleton\n";
              stop:=true (* on se donne une chance de finir la propagation *)
          | Some (v,b) ->
              Printf.eprintf "Singleton trouvés\n";
              affect v b
      end; 
      match formule#find_single_polarite with
        | None -> 
            Printf.eprintf "Pas de polarité unique\n";
            () (* si stop était à true, la propagation s'arrète ici *)
        | Some (v,b) ->
            Printf.eprintf "Polarité unique\n";
            stop:=false; (* la propagation doit refaire un tour... *)
            affect v b
    done; 
    Fine (!var_add)
  with 
      Clause_vide ->
        List.iter (fun var -> formule#reset_val var) !var_add; 
        Conflict 



let dpll formule = 

  let try_pari var b =
    try
      Printf.eprintf "Betting %d is %b" var b;
      formule#set_val b var
    with
        Clause_vide ->
          assert false in

  let rec aux () = (* renvoie true si en pariant b, ou plus, sur v on peut prolonger les paris actuels en qqchose de satisfiable *)(* "b ou plus" = true et false si b=true, juste false sinon *)
    match constraint_propagation formule with
      | Conflict -> 
          Printf.eprintf "Conflit!\n";
          false
      |  Fine var_prop -> 
          match next_pari formule with
            | None -> 
                Printf.eprintf "Done\n";
                true (* plus aucun pari à faire, c'est gagné *)
            | Some var -> 
                try_pari var true;
                if aux () then
                  true
                else
                  begin
                    formule#reset_val var;
                    try_pari var false;
                    if aux() then
                      true
                    else
                      begin
                        formule#reset_val var;
                        false
                      end
                  end
  in if aux () then 
      Solvable formule#get_paris
    else 
      Unsolvable

















