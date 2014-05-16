open Algo
open Clause
open Debug
open Formule_dpll
open Formule
open Algo_base

let name = "Dpll"

type formule = formule_dpll

(* propage en ajoutant à acc les littéraux assignés
   lit est un argument ignoré *)
let rec constraint_propagation pure_prop (formule:formule) lit etat acc =
  stats#start_timer "Propagation (s)"; (***)
  let lvl = etat.level in
  let rec propagate acc =
    match formule#find_singleton with 
      | None ->
          if pure_prop then
            begin
              match formule#find_single_polarite with
                | None -> acc (* propagation terminée *)
                | Some (b,v) -> (* single polarité trouvée *)  
                    try
                      debug#p 3 "Propagation : single polarity found : %d %B" v b;
                      debug#p 4 "Propagation : setting %d to %B" v b;
                      formule#set_val b v lvl; (* on assigne, peut lever Empty_clause *)
                      propagate ((b,v)::acc) (* on empile et on poursuit *)
                    with                 
                        Empty_clause c -> (* conflit *)
                          stats#stop_timer "Propagation (s)"; 
                          raise (Conflit_prop (c,(b,v)::acc)) 
            end
          else
            acc
      | Some ((b,v),c) -> (* singleton trouvé *)
          try
            debug#p 3 "Propagation : singleton found : %d %B in clause %d" v b c#get_id;
            debug#p 4 "Propagation : setting %d to %B (origin : clause %d)" v b c#get_id;
            formule#set_val b v ~cl:c lvl;
            propagate ((b,v)::acc) (* on empile et on poursuit *)
          with
              Empty_clause c -> 
                stats#stop_timer "Propagation (s)"; 
                raise (Conflit_prop (c,(b,v)::acc))
  in
  let res = propagate acc in
  stats#stop_timer "Propagation (s)";
  res
     
let init n cnf = 
  let f = new formule_dpll in
  f#init n cnf;
  f#check_empty_clause; (* lève Unsat si il y avait une clause vide dans la formule de départ *)
  try
    let prop = constraint_propagation (**pure_prop*) f (true,0) { tranches = []; level = 0 } [] in (* propagation initiale *)
    (f,prop)
  with Conflit_prop _ -> raise Unsat

let set_wls _ _ _ _ = ()
