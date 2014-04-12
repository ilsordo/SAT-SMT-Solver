open Algo
open Clause
open Debug
open Formule_wl
open Formule

type etat = { formule : formule_wl; tranches : tranche list }

let name = "Wl"

(***)

let rec assign (formule : formule_wl) (b,v) acc =
  (* Fait une assignation et propage *)
  debug#p 5 "Propagation : setting %d to %B" v b;
  try
    formule#set_val b v; (* on parie b sur var *)
    debug#p 3 "WL : Moving old wl's on (%B,%d)" (not b) v;
    (* on parcourt  les clauses où var est surveillée et est devenue fausse, ie là où il faut surveiller un nouveau littéral *) 
    (formule#get_wl (not b,v))#fold (constraint_propagation formule (b,v)) ((b,v)::acc)
  with
    | Clause_vide -> raise (Conflit ((b,v)::acc))

and constraint_propagation (formule : formule_wl) (b,v) c acc =
  match (formule#update_clause c (not b,v)) with
    | WL_Conflit ->
        stats#record "Conflits";
        debug#p 2 ~stops:true "WL : Conflict : clause %d false " c#get_id;
        debug#p 4 "Propagation : cannot leave wl %B %d in clause %d" (not b) v c#get_id; 
        raise (Conflit ((b,v)::acc)) (* Tu confirmes ? *)
    | WL_New (b_new, v_new) -> 
        debug#p 4 "Propagation : watched literal has moved from %B %d to %B %d in clause %d" (not b) v b_new v_new c#get_id ; 
        acc
    | WL_Assign (b_next,v_next) -> 
        debug#p 4 "Propagation : setting %d to %B in clause %d is necessary (leaving %B %d impossible)" v_next b_next c#get_id (not b) v; 
        assign formule (b_next,v_next) acc
    | WL_Nothing -> 
        debug#p 4 "Propagation : clause %d satisfied (leaving wl %B %d unnecessary)" c#get_id (not b) v; 
        acc
(***)

let init n cnf =
  let f = new formule_wl in
  f#init n cnf;
  if f#check_empty_clause then
    begin
      f#init_wl;
      { formule = f; tranches = [] }
    end 
  else
    raise (Conflit [])

let make_bet (b,v) etat =
  begin
    try
      etat.formule#set_val b v
    with Clause_vide -> raise (Conflit []) (* On a créé une clause vide en faisant le pari *)
  end;
  let propagation = (etat.formule#get_wl (not b,v))#fold (constraint_propagation etat.formule (b,v)) [] in
  { etat with tranches = ((b,v),propagation)::etat.tranches }

let undo_assignation formule (b,v) = 
  debug#p 3 "Unsetting %d : %B" v b;
  formule#reset_val v

let recover (pari,propagation) etat =
  List.iter (undo_assignation etat.formule) propagation;
  undo_assignation etat.formule pari;
  etat

let undo etat = match etat.tranches with
  | [] -> assert false (* Je ne vois pas pourquoi cela arriverait *)
  | (pari,propagation)::q ->
      List.iter (undo_assignation etat.formule) propagation;
      undo_assignation etat.formule pari;
      { etat with tranches = q }

let get_formule { formule = formule ; _ } = (formule:>formule)



