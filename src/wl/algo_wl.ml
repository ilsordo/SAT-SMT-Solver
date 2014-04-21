open Algo
open Clause
open Debug
open Formule_wl
open Formule

let name = "Wl"

type formule = formule_wl
       
let constraint_propagation (formule : formule) (b,v) etat acc = (* propage en partant de (b,v), renvoie la liste de tous les littéraux assignés *)
  stats#start_timer "Prop (s)";
  let lvl = etat.level in
  let rec assign (b,v) c acc = 
    try
      debug#p 4 "Propagation : setting %d to %B (origin : clause %d)" v b c#get_id;
      formule#set_val b v ~cl:c lvl; (* on parie b sur var *)
      debug#p 3 "Propagation : Moving old wl's on (%B,%d)" (not b) v;
      (* on parcourt  les clauses où var est surveillée et est devenue fausse, ie là où il faut surveiller un nouveau littéral *) 
      (formule#get_wl (not b,v))#fold (propagate (b,v)) ((b,v)::acc)
    with
      | Empty_clause c -> raise (Conflit_prop (c,(b,v)::acc))
  and propagate (b,v) c acc = (* update des jumelles de c (suivant (b,v)), propage, renvoie les assignations effectuées *)
    match (formule#update_clause c (not b,v)) with
      | WL_Conflit ->
          debug#p 3 "Propagation : cannot leave wl %B %d in clause %d" (not b) v c#get_id; 
          raise (Conflit_prop (c,acc))
      | WL_New (b_new, v_new) -> 
          debug#p 3 "Propagation : watched literal has moved from %B %d to %B %d in clause %d" (not b) v b_new v_new c#get_id ; 
          acc
      | WL_Assign (b_next,v_next) -> 
          debug#p 3 "Propagation : setting %d to %B in clause %d is necessary (leaving %B %d impossible)" v_next b_next c#get_id (not b) v; 
          assign (b_next,v_next) c acc
      | WL_Nothing -> 
          debug#p 3 "Propagation : clause %d satisfied (leaving wl %B %d unnecessary)" c#get_id (not b) v; 
          acc
  in
    (formule#get_wl (not b,v))#fold (propagate (b,v)) acc

let init n cnf = (* initialise la formule et renvoie un état *)
  let f = new formule_wl in
  f#init n cnf;  (* fait des assignations, contrairement à DPLL, mais ne trouve pas d'éventuels conflits *)
  f#check_empty_clause; (* peut lever Unsat *)
  f#init_wl; (* pose les jumelles *)
  f

let set_wls formule c l l0 = formule#set_wl l l0 c
