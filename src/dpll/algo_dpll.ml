open Algo
open Clause
open Debug
open Formule_dpll
open Formule

let name = "Dpll"

type formule = formule_dpll

(* propage en ajoutant à acc les littéraux assignés
   si cl est vrai, enregistre les clauses ayant provoqué chaque assignation *)
let rec constraint_propagation (formule:formule) lit etat acc =
  stats#start_timer "Propagation (s)"; (***)
  let lvl = etat.level in
  let rec propagate acc =
    match formule#find_singleton with 
      | None ->
          begin
            match formule#find_single_polarite with
              | None -> acc
              | Some (b,v) ->   
                  try
                    debug#p 3 "Propagation : single polarity found : %d %B" v b;
                    debug#p 4 "Propagation : setting %d to %B" v b;
                    formule#set_val b v lvl;
                    propagate ((b,v)::acc) (* on empile et on poursuit *)
                  with                 
                    Empty_clause c -> 
                      stats#stop_timer "Propagation (s)"; (***) 
                      raise (Conflit_prop (c,(b,v)::acc)) 
          end
      | Some ((b,v),c) ->
          try
            debug#p 3 "Propagation : singleton found : %d %B in clause %d" v b c#get_id;
            debug#p 4 "Propagation : setting %d to %B (origin : clause %d)" v b c#get_id;
            formule#set_val b v ~cl:c lvl;
            propagate ((b,v)::acc)
          with
            Empty_clause c -> 
              stats#stop_timer "Propagation (s)"; (***) 
              raise (Conflit_prop (c,(b,v)::acc))
  in
    let res = propagate acc in
    stats#stop_timer "Propagation (s)"; (***) 
    res (** complexité de sauver res pour l'envoyer juste après ? *)
     
let init n cnf = 
  let f = new formule_dpll in
  f#init n cnf;
  f#check_empty_clause; (* peut lever Unsat *)
  try
    let _ = constraint_propagation f (true,0) { tranches = []; level = 0 } [] in (* propagation initiale *)
    f
  with Conflit_prop _ -> raise Unsat

let set_wls _ _ _ _ = ()
