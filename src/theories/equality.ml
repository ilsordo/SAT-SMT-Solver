open Union_find
open Formula_tree

type atom = Eq of string*string | Ineq of string*string



let parse_atom s =
  try
    Scanf.sscanf s "x%d=x%d" (fun 
  
module UF = Union_find.Make(struct type t = string let eq a b = (a = b) end)

module String_set = Set.Make(struct type t = (string*string) let compare = compare)

type etat = 
  { 
    unions : UF.t;
    differences : String_set.t
  }


(** Normalisation *)

let rec normalize formula = 
  let rec normalize_atom (Atom a) = match a with
    | Eq (s1,s2) -> if s1 < s2 then Atom a else Atom (Eq (s2,s1))
    | Ineq (s1,s2) -> if s1 < s2 then Atom a else Atom (Ineq (s2,s1)) 
  in
    match formula with
      | And (f1,f2) -> And (normalize f1,normalize f2)
      | Or (f1,f2) -> Or (normalize f1,normalize f2)
      | Imp (f1,f2) -> Imp (normalize f1,normalize f2)
      | Equ (f1,f2) -> Equ (normalize f1,normalize f2)
      | Not f -> Not (normalize f)
      | Atom a -> normalize_atom (Atom a) 
  
  
(** Initialisation *)

let init reduc = 
  { 
    unions = UF.empty;
    differences = String_set.empty
  }


(** Propagation *)
 

let propagate reduction prop etat = (* propagation tout-en-un *)
  let rec aux prop etat = match prop with
    | [] -> etat
    | l::q ->
        begin 
          match reduc.get_orig l with
            | None -> aux q etat
            | Some a -> 
                begin
                  match a with
                    | Eq (s1,s2) -> aux q {etat with unions = UF.union s1 s2 etat.unions}
                    | Ineq (s1,s2) -> aux q {etat with differences = String_set.add (s1,s2) etat.differences}
                end
        end in
  let unions = 
    String_set.fold
      (fun (s1,s2) unions ->
         let (b,unions) = UF.are_equal s1 s2 unions in
         if b then
           unions
         else
           match UF.explain s1 s2 unions with
             | None -> assert false
             | Some l ->
                 let explain = 
                   List.fold_left
                     (fun l (s1,s2) ->
                        if s1 < s2 then (reduction.get_id (Eq (s1,s2)))::l else (reduction.get_origin (Eq (s2,s1)))::l)
                     [] l in 
                 Raise Conflit_smt (explain,{etat with unions = unions}))
      etat.unions in
  {etats with unions = unions}
  
  
(** Backtrack *)
  
let backtrack reduc undo_list etat =
  let rec aux etat = function
    | [] -> etat
    | l::q ->
        begin
          match reduc.get_orig l with
            | None -> aux etat q
            | Some a -> 
                begin
                  match a with
                    | Eq (s1,s2) -> aux {etat with unions = UF.undo_last s1 s2 etat.unions} q
                    | Ineq (s1,s2) -> aux {etat with differences = String_set.remove (s1,s1) etat.differences} q
                end
        end in
  aux etat undo_list

let print_etat reduc etat = 
  ...
  
let pure_prop = false


