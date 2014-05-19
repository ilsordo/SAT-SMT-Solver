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
    | Ineq (s1,s2) -> Not(normalize (Atome (Eq (s1,s2)))) in
  match formula with
    | And (f1,f2) -> And (normalize f1,normalize f2)
    | Or (f1,f2) -> Or (normalize f1,normalize f2)
    | Imp (f1,f2) -> Imp (normalize f1,normalize f2)
    | Equ (f1,f2) -> Equ (normalize f1,normalize f2)
    | Not f -> Not (normalize f)
    | Atom a -> normalize_atom (Atom a) 
  
  
(** Initialisation *)

let init _ = 
  { 
    unions = UF.empty;
    differences = String_set.empty
  }


(** Propagation *)
 
let propagate_unit (b,v) reduction etat = (* propager dans la théorie l'assignation du littéral (b,v) *)
  match reduction#get_orig v with
    | None -> etat 
    | Some a -> 
        begin
          match a with
            | Eq (s1,s2) when s1 < s2-> 
                if b then
                  {etat with unions = UF.union s1 s2 etat.unions}
                else
                  {etat with differences = String_set.add (s1,s2) etat.differences}
            | _ -> assert false
        end


let explain_conflict s1 s2 reduction unions = (* expliquer pourquoi s1 et s2 ne sont pas dans le même ensemble *)
  match UF.explain s1 s2 unions with
    | None -> assert false
    | Some l ->
        begin
          let id x y = match reduction#get_id (Eq (x,y)) with
            | None -> assert false
            | Some v -> v in
          let explain = 
            List.fold_left
              (fun l (s1,s2) ->
                if s1 < s2 then (true,id s1 s2)::l else (true,id s2 s1)::l) (** attention doublons. true ? *)
              [] l in 
          Raise Conflit_smt (explain,{etat with unions = unions})
        end
                       
let propagate reduction prop etat =
  let etat = List.fold_left (fun etat l -> propagate_unit l reduction etat) etat prop in (* ajouter toutes les unions et diff contenues dans prop *)
  let unions = (* vérifier si inconsistance créée *)
    String_set.fold
      (fun (s1,s2) unions ->
         let (b,unions) = UF.are_equal s1 s2 unions in
         if b then
           unions
         else
           explain_conflict s1 s2 reduction unions) (* raise Conflit_smt *)
      etat.differences etat.unions in (* fold sur etat.differences *)
  {etats with unions = unions}
  
  
(** Backtrack *)
  
let backtrack_unit (b,v) reduction etat = 
  match reduction#get_orig v with
    | None -> etat
    | Some a -> 
        begin
          match a with
            | Eq (s1,s2) when s1 < s2-> 
                if b then
                  {etat with unions = UF.undo_last s1 s2 etat.unions}
                else
                  {etat with differences = String_set.remove (s1,s1) etat.differences}
            | _ -> assert false
        end
        
        
let backtrack reduc undo_list etat =
  List.fold_left (fun etat l -> backtrack_unit l reduction etat) etat undo_list


(** Affichage du résultat *)

let get_answer reduc etat result p =
  reduc#iter
    (fun a v -> 
      match values#find v with
        | None -> assert false
        | Some b ->
            begin
              match a with
                | Eq(s1,s2) when s1 < s2 -> let ope = if b then "=" else "!=" in Printf.fprintf p "%s %s %s\n" s1 ope s2                
                | _ -> assert false
            end)

  
let pure_prop = false


