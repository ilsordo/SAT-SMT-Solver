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
  match formule#find_singleton with (* on cherche des clauses singletons *)
    | None ->
        begin
          match formule#find_single_polarite with (* on cherche des variables n'apparaissant qu'avec une seule polarité *)
            | None -> Fine l (* ni singleton, ni variable avec une seule polarité >> on a mené la propagation aussi loin que possible, on renvoie la liste des variables assignées depuis le dernier pari *)
            | Some (v,b) ->   
                try
                  debug 3 "Propagation : singleton found : %d %B" v b;
                  debug 4 "Propagation : setting %d to %B" v b;
                  formule#set_val b v; (* on assigne v selon sa polarité unique *)
                  constraint_propagation formule (v::l) (* on essaye de poursuivre la propagation *)
                with
                  Clause_vide -> (* on a créé une clause vide, il faut annuler toutes les assignations depuis le dernier pari *)
                    begin
                      debug 3 "Propagation : empty clause found";
                      List.iter (fun var -> formule#reset_val var) (v::l);
                      Conflict
                    end
        end
    | Some (v,b) -> (* on a trouvé une clause singleton *)
        try
          debug 3 "Propagation : single polarity found : %d %B" v b;
          debug 4 "Propagation : setting %d to %B" v b;
          formule#set_val b v; (* on assigne la variable selon son apparition dans la clause singleton *)
          constraint_propagation formule (v::l) (* on poursuit la propagation *)
        with
          Clause_vide -> (* clause vide : on annule tout *)
            begin
              debug 3 "Propagation : empty clause found";
              List.iter (fun var -> formule#reset_val var) (v::l);
              Conflict
            end   
                
            
(*************)        
            
            
(* Algo DPLL *)
let algo n cnf = 
  let formule = new formule_dpll in

  let try_pari var b = (* assigne b à la variable var, fait évoluer les clauses en conséquence *)
    debug 2 "DPLL : trying with %d %B" var b;
    try
      formule#set_val b var
    with
        Clause_vide ->
          assert false in
  

  let rec aux () =  (* essaye de poursuivre les assignations courantes jusqu'à rendre la formule vraie. Renvoie true si réussit, false si impossible *)
    debug 2 "DPLL : starting propagation";
    match constraint_propagation formule [] with (* on commence par faire les assignations nécessaires (singletons, polarité unique) *)
      | Conflict -> 
          record_stat "Conflits";
          debug 2 ~stops:true "DPLL : conflict found";
          false
      |  Fine var_prop -> 
          match next_pari formule with (* un pari est nécessaire pour prolonger l'assignation courante des variables *)
            | None -> 
                debug 1 "Done\n";
                true (* plus aucun pari à faire, c'est gagné *)
            | Some var -> 
                record_stat "Paris";
                try_pari var true; (* on fait un pari : true sur var *)
                if aux () then (* on essaye de le prolonger *)
                  true (* on a rendu la formule satisfiable *)
                else
                  begin
                    formule#reset_val var; (* on doit annuler le pari *)
                    try_pari var false; (* on retente un autre pari : false sur var *)
                    if aux() then (* on essaye de le prolonger *)
                      true (* on a rendu la formule satisfiable *)
                    else
                      begin
                        debug 2 "DPLL : backtracking on var %d" var;
                        List.iter (fun v -> formule#reset_val v) var_prop; (* plus d'espoir, il faut bactracker. On annule toutes les assignations faites depuis le dernier pari *)
                        formule#reset_val var; (* on doit annuler le pari *)
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
