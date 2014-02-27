open Answer
open Formule
open Formule_dpll
open Clause
open Debug

type propagation_result = Fine of variable list | Conflict (* C'est juste pour la lisibilité du code, si tu aimes pas on peut le virer *)

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

let constraint_propagation formule = (* Renvoie Conflict et annule la propagatiob si une clause vide a été générée, Fine sinon*)
  let var_add = ref [] in (* variables ayant été affectées *)
  let stop = ref false in (* stop = false : il y a encore à propager, stop = true : on a fini de propager *)
  let affect v b =
    debug 4 "Propagation : setting %d to %B" v b;
    var_add := v::(!var_add);
    formule#set_val b v in (* Peut lever une exception qui est attrapée plus loin *)
  try
    while not (!stop) do
      begin
        match formule#find_singleton with
          | None ->
              stop:=true (* on se donne une chance de finir la propagation *)
          | Some (v,b) ->
              debug 3 "Propagation : singleton found : %d %B" v b;
              affect v b
      end; 
      match formule#find_single_polarite with
        | None -> 
            () (* si stop était à true, la propagation s'arrète ici *)
        | Some (v,b) ->
            debug 3 "Propagation : single polarity found : %d %B" v b;
            stop:=false; (* la propagation doit refaire un tour... *)
            affect v b
    done; 
    Fine (!var_add)
  with 
      Clause_vide ->
        List.iter (fun var -> formule#reset_val var) !var_add; 
        Conflict 



let algo n cnf = 
  let formule = new formule_dpll in
  formule#init n cnf;

  let try_pari var b =
    debug 1 "Dpll : trying with %d %B" var b;
    try
      formule#set_val b var
    with
        Clause_vide ->
          assert false in
  
  let rec aux () =
    record_stat "Propagation";
    debug 2 "Dpll : starting propagation";
    match constraint_propagation formule with
      | Conflict -> 
          record_stat "Conflits";
          debug 2 ~stops:true "Dpll : conflict found";
          false
      |  Fine var_prop -> 
          debug 2 "Dpll : starting constraint propagation";
          match next_pari formule with
            | None -> 
                debug 1 "Done";
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
                        debug 1 "Dpll : backtracking on var %d" var;
                        List.iter (fun v -> formule#reset_val v) var_prop;
                        formule#reset_val var;
                        false
                      end
                  end in
  try 
    formule#check_empty_clause;
    if aux () then 
      Solvable formule#get_paris
    else 
      Unsolvable
  with
    | Clause_vide -> Unsolvable (* Clause vide dès le début *)

















