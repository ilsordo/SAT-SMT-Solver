open Union_find
open Formula_tree
open Clause
open Debug

type atom = string*string
  
module UF = Union_find.Make(struct type t = string let eq a b = (a = b) end)

module String_set = Set.Make(struct type t = (string*string) let compare = compare end)

type etat = 
  { 
    unions : UF.t;
    differences : String_set.t
  }

exception Conflit_smt of (literal list*etat)

let parse lexbuf =
  try
    Equality_parser.main Equality_lexer.token lexbuf
  with
    | Failure _ | Equality_parser.Error ->
        Printf.eprintf "Input error\n%!";
        exit 1

let print_atom _ _ = ()
  
(** Initialisation *)

let init _ = 
  { 
    unions = UF.empty; (* ensembles d'union-find *)
    differences = String_set.empty (* ensemble des diségalités *)
  }


(** Propagation *)
 
let propagate_unit (b,v) reduction etat = 
  match reduction#get_orig v with
    | None -> etat 
    | Some (s1,s2) -> 
        if b then (* c'est une union *)
          {etat with unions = UF.union s1 s2 etat.unions}
        else (* c'est une désunion *)
          {etat with differences = String_set.add (s1,s2) etat.differences}


let explain_conflict s1 s2 reduction unions etat = (* expliquer pourquoi s1 et s2 ne sont pas dans le même ensemble *)
  match UF.explain s1 s2 unions with
    | None -> assert false
    | Some l -> (* l : ensemble des unions qui ont conduits s1 et s2 à être ensembles *)
        begin
          let id x y = 
            let (inf,sup) = if x < y then (x,y) else (y,x) in
            match reduction#get_id (inf,sup) with
              | None -> assert false
              | Some v -> v in
          let explain = 
            List.fold_left
              (fun l (s1,s2) -> debug#p 1 "explain %s et %s" s1 s2; (false,id s1 s2)::l) (* inversion des polarité *)
              [] l in 
          raise (Conflit_smt ((true,id s1 s2)::explain,{etat with unions = unions}))
        end
                       
let propagate reduction prop etat = (* propager les assignations effectuées par dpll *)
  let etat = List.fold_left (fun etat lit -> propagate_unit lit reduction etat) etat prop in (* ajouter toutes les unions et diff contenues dans prop *)
  let unions = (* vérifier si inconsistance créée *)
    String_set.fold
      (fun (s1,s2) unions ->
         debug#p 2 "Are unif ? %s et %s" s1 s2; 
         let (b,unions) = UF.are_equal s1 s2 unions in
         if not b then
           unions
         else
           explain_conflict s1 s2 reduction unions etat) (* raise Conflit_smt *)
      etat.differences etat.unions in (* fold sur etat.differences *)
  {etat with unions = unions}
  
  
(** Backtrack *)
  
let backtrack_unit (b,v) reduction etat = 
  match reduction#get_orig v with
    | None -> etat
    | Some (s1,s2) -> 
        if b then
          {etat with unions = UF.undo_last s1 s2 etat.unions}
        else
          {etat with differences = String_set.remove (s1,s2) etat.differences}
        
        
let backtrack reduc undo_list etat = (* backtracker undo_list dans la théorie *)
  List.fold_left (fun etat lit -> backtrack_unit lit reduc etat) etat undo_list


(** Affichage du résultat *)

let print_answer reduc etat result p =
  reduc#iter
    (fun (s1,s2) v -> 
      match result#find v with
        | None -> assert false
        | Some b ->
            let ope = if b then "=" else "!=" in Printf.fprintf p "%s %s %s\n" s1 ope s2)

  
let pure_prop = false


