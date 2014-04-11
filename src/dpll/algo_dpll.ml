open Algo
open Clause
open Debug
open Formule_dpll
open Formule

type etat = { formule : formule_dpll; tranches : tranche list }

let name = "Dpll"

(***)
let rec constraint_propagation formule =
  let rec aux acc = 
    match formule#find_singleton with(* on cherche des clauses singletons *)
      | None ->
          begin
            match formule#find_single_polarite with (* on cherche des variables n'apparaissant qu'avec une seule polarité *)
              | None -> acc (* ni singleton, ni variable avec une seule polarité >> on a mené la propagation aussi loin que possible, on renvoie la liste des variables assignées depuis le dernier pari *)
              | Some (b,v) ->   
                  try
                    debug#p 3 "Propagation : singleton found : %d %B" v b;
                    debug#p 4 "Propagation : setting %d to %B" v b;
                    formule#set_val b v; (* on assigne v selon sa polarité unique *)
                    aux ((b,v)::acc) (* on essaye de poursuivre la propagation *)
                  with
                      Clause_vide -> raise (Conflit ((b,v)::acc)) (* on a créé une clause vide, il faut annuler toutes les assignations depuis le dernier pari *)
          end
      | Some (b,v) -> (* on a trouvé une clause singleton *)
          try
            debug#p 3 "Propagation : single polarity found : %d %B" v b;
            debug#p 4 "Propagation : setting %d to %B" v b;
            formule#set_val b v; (* on assigne la variable selon son apparition dans la clause singleton *)
            aux ((b,v)::acc) (* on poursuit la propagation *)
          with
              Clause_vide -> raise (Conflit ((b,v)::acc)) (* clause vide : on annule tout *) in
  aux []
(***)

let init n cnf =
  let f = new formule_dpll in
  f#init n cnf;
  if f#check_empty_clause then
    let _ = constraint_propagation f in
    { formule = f; tranches = [] }
  else
    raise (Conflit [])

let make_bet (b,v) etat =
  begin
    try
      etat.formule#set_val b v
    with Clause_vide -> raise (Conflit [])(* On a créé une clause vide en faisant le pari *)
  end;
  let propagation = constraint_propagation etat.formule in
  { etat with tranches = ((b,v),propagation)::etat.tranches }

let undo_assignation formule (_,v) = formule#reset_val v

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










