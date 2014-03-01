open Answer
open Formule
open Formule_dpll
open Clause
open Debug

type propagation_result = Fine of variable list | Conflict 

(*************)

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

(*************)

(* constraint_propagation : 
    doit effectuer toutes les propagations possibles
      si conflit : doit annuler toutes les assignations propagées + renvoyer Conflict
      si ok : renvoie Fine l où l est l'ensemble des variables assignées *) 
let rec constraint_propagation formule l = 
  match formule#find_singleton with
    | None ->
        begin
          match formule#find_single_polarite with
            | None -> Fine l
            | Some (v,b) ->   
                try
                  debug 3 "Propagation : singleton found : %d %B" v b;
                  debug 4 "Propagation : setting %d to %B" v b;
                  formule#set_val b v;
                  constraint_propagation formule (v::l)
                with
                  Clause_vide -> 
                    begin
                      List.iter (fun var -> formule#reset_val var) (v::l);
                      Conflict
                    end
        end
    | Some (v,b) ->
        try
          debug 3 "Propagation : single polarity found : %d %B" v b;
          debug 4 "Propagation : setting %d to %B" v b;
          formule#set_val b v;
          constraint_propagation formule (v::l)
        with
          Clause_vide -> 
            begin
              List.iter (fun var -> formule#reset_val var) (v::l);
              Conflict
            end   
                
            
(*************)        
            
            
(* Algo dpll *)
let algo n cnf = 
  let formule = new formule_dpll in

  let try_pari var b =
    debug 2 "Dpll : trying with %d %B" var b;
    record_stat "Paris";
    try
      formule#set_val b var
    with
        Clause_vide ->
          assert false in
  
  (* Renvoie true si la propagation réussit, false sinon *)
  let rec aux () =
    debug 2 "Dpll : starting propagation";
    match constraint_propagation formule [] with
      | Conflict -> 
          record_stat "Conflits";
          debug 2 ~stops:true "Dpll : conflict found";
          false
      |  Fine var_prop -> 
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
                        debug 2 "Dpll : backtracking on var %d" var;
                        List.iter (fun v -> formule#reset_val v) var_prop;
                        formule#reset_val var;
                        false
                      end
                  end in
  try 
    formule#init n cnf;
    formule#check_empty_clause; (* Lève Clause_vide si une clause est vide *)
    if aux () then 
      Solvable formule#get_paris
    else 
      Unsolvable
  with
    | Clause_vide -> Unsolvable (* Clause vide dès le début *)
