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
    var_add := v::(!var_add);
    formule#set_val b v in (* Peut lever une exception qui est attrapée plus loin *)
  try
    while not (!stop) do
      let singletons = formule#find_singleton in (* toute les variables qui forment des clauses singletons *)
      if singletons#is_empty then 
        stop:=true (* on se donne une chance de finir la propagation *)
      else   
        singletons#iter affect;        
      match formule#find_single_polarite with
        | None -> () (* si stop était à true, la propagation s'arrète ici *)
        | Some (v,b) ->
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
      formule#set_val b var;
      true
    with
      Clause_vide ->
        formule#reset_val var;
        false      in

  let rec aux () = (* renvoie true si en pariant b, ou plus, sur v on peut prolonger les paris actuels en qqchose de satisfiable *)(* "b ou plus" = true et false si b=true, juste false sinon *)
      match constraint_propagation formule with
        | Conflict -> false
        |  Fine var_prop -> 
            match next_pari formule with
              | None -> true (* plus aucun pari à faire, c'est gagné *)
              | Some var -> 
                  if try_pari var true then
                    if aux() then
                      true
                    else 
                      begin
                        formule#reset_val var;
                        if try_pari var false then
                          if aux() then
                            true
                          else 
                            begin
                              formule#reset_val var;
                              false
                            end
                        else
                          false
                      end
                  else
                    if try_pari var false then
                      if aux() then
                        true
                      else 
                        begin
                          formule#reset_val var;
                          false
                        end
                    else
                      false
  in if aux () then 
    Solvable formule#get_paris
  else 
    Unsolvable

















