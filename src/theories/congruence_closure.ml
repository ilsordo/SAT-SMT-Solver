open Formula_tree
open Union_find
open Congruence_type

(*type term = Var of string | Fun of string * (term list)*)

(*type atom = Eq of term*term | Ineq of term*term*)

type term = Congruence_type.t

include Equality

module Fun_map = Map.Make(struct type t = string * (term list) let compare = compare end)
module Arg_map = Map.Make(struct type t = string let compare = compare end)
module Arg_set = Set.Make(struct type t = term list let compare = compare end)


(*
type etat = 
  { 
    ack_assoc : string Fun_map.t; (* ancien nom -> nouveau nom *)
    ack_arg : Arg_set.t Arg_map.t ; (* que des anciens noms *)
    unions : UF.t;
    differences : String_set.t
  }



(*

notes persos

    pour l'instant : on oublie l'affichage final qu devra distinguer les termes des sous termes / égalités ajoutées
    si travail avec type atom normalisé on peut déléguer fonctions à equality.ml avec etat = { redu... sub_etat}    

    attention au rev sur les listes d'args

                                            map
    nom de f * arg  (string * (term list)) ----> renommage (string pour Var of string)   :   permet init sans ajout de clauses (1ère passe
    
                              map
    nom de fonction (string) ----> set arguments (set of term list) : pour 2ème 
    
    2ème passe : maintenant on a la fonction ack, on va ajouter à la formule précédente (qui a été remplacée à la volée) la deuxième partie
      sur la 2ème map : 
        pour chaque nom de fonction f
          pour chaque couple (l1,l2) de term list
            produire la conjonction grâce à ack (préecrite pour propreté)
            rechercher dans la première map le bind de f l1 et f l2
            ajouter la clause
*)

(*
let normalize formula = (* idem à equality *)
  let rec normalize_atom (Atom a) = match a with
    | Eq (t1,t2) -> if t1 < t2 then Atom a else Atom (Eq (t2,t1))
    | Ineq (t1,t2) -> Not(normalize (Atome (Eq (t1,t2)))) in
  match formula with
    | And (t1,t2) -> And (normalize t1,normalize t2)
    | Or (t1,t2) -> Or (normalize t1,normalize t2)
    | Imp (t1,t2) -> Imp (normalize t1,normalize t2)
    | Equ (t1,t2) -> Equ (normalize t1,normalize t2)
    | Not f -> Not (normalize f)
    | Atom a -> normalize_atom (Atom a) 
*)

(* point de non retour *)
*)

(** Transformation 1 : remplacer les termes et sous termes par des variables fraiches (inutile de le faire pour les variables) *)

let add_set f l ack_arg = (* ajouter l dans le set associé à f *) 
  let set =
    try
      Arg_map.find f ack_arg
    with
      | Not_found -> Arg_set.empty in
  Arg_map.add f (Arg_set.add l set) ack_arg

let rec ackerize1_term t free ack_assoc ack_arg = (* transformer un terme *)
  match t with
    | Var s -> (s, free, ack_assoc, ack_arg)
    | Fun (f,l) -> 
        try
          (Fun_map.find (f,l) ack_assoc, free, ack_assoc, ack_arg)
        with
          | Not_found -> 
              let s = "_ack"^(string_of_int free) in (** autre syntaxe ? *)
              let ack_assoc = Fun_map.add (f,l) s ack_assoc in
              let ack_arg = add_set f l ack_arg in
              let (l_ack,free,ack_assoc,ack_arg) = ackerize1_list l (free+1) ack_assoc ack_arg [] in
                (s(**Fun (s,l_ack)*), free, ack_assoc, ack_arg)


and ackerize1_list l free ack_assoc ack_arg acc = (* transformer une liste de termes *)
  match l with
    | [] -> (List.rev acc,free,ack_assoc,ack_arg) (* on retourne la liste pour remettre les arguments dans l'ordre *)
    | t::q -> 
        let (t_ack,free,ack_assoc,ack_arg) = ackerize1_term t free ack_assoc ack_arg in
          ackerize1_list q free ack_assoc ack_arg (t_ack::acc)
                  
                  
let ackerize1_atom (t1,t2) free ack_assoc ack_arg = (* transformer un atome *)  
  let (a_ack1,free,ack_assoc,ack_arg) = ackerize1_term t1 free ack_assoc ack_arg in
  let (a_ack2,free,ack_assoc,ack_arg) = ackerize1_term t2 free ack_assoc ack_arg in
    if a_ack1 < a_ack2 then
      ((a_ack1,a_ack2),free,ack_assoc,ack_arg)
    else
      ((a_ack2,a_ack1),free,ack_assoc,ack_arg)

          
let ackerize1 (formula : (term*term) formula_tree) = (* transformer une formule, renvoyer aussi ack_assoc et ack_arg (mais pas forcèment nécessaire suivant ce qu'on souhaite print à la fin *)
  let rec aux f free ack_assoc ack_arg = match f with
    | And (f1,f2) -> 
        let (f_ack1,free,ack_assoc,ack_arg) = aux f1 free ack_assoc ack_arg in
        let (f_ack2,free,ack_assoc,ack_arg) = aux f2 free ack_assoc ack_arg in
          (And(f_ack1,f_ack2),free,ack_assoc,ack_arg)
    | Or (f1,f2) -> 
        let (f_ack1,free,ack_assoc,ack_arg) = aux f1 free ack_assoc ack_arg in
        let (f_ack2,free,ack_assoc,ack_arg) = aux f2 free ack_assoc ack_arg in
          (Or(f_ack1,f_ack2),free,ack_assoc,ack_arg)
    | Imp (f1,f2) -> 
        let (f_ack1,free,ack_assoc,ack_arg) = aux f1 free ack_assoc ack_arg in
        let (f_ack2,free,ack_assoc,ack_arg) = aux f2 free ack_assoc ack_arg in
          (Imp(f_ack1,f_ack2),free,ack_assoc,ack_arg)    
    | Equ (f1,f2) ->
        let (f_ack1,free,ack_assoc,ack_arg) = aux f1 free ack_assoc ack_arg in
        let (f_ack2,free,ack_assoc,ack_arg) = aux f2 free ack_assoc ack_arg in
          (Equ (f_ack1,f_ack2),free,ack_assoc,ack_arg)   
    | Not f ->
        let (f_ack,free,ack_assoc,ack_arg) = aux f free ack_assoc ack_arg in
          (Not f_ack,free,ack_assoc,ack_arg)    
    | Atom a ->  
        let (a_ack,free,ack_assoc,ack_arg) = ackerize1_atom a free ack_assoc ack_arg in
          (Atom a_ack,free,ack_assoc,ack_arg) in
  let (f_ack,_,ack_assoc,ack_arg) = aux formula 1 Fun_map.empty Arg_map.empty in
    (f_ack,ack_assoc,ack_arg)
  
(** Transformation 2 : ajouter des implications *)

let get_var t ack_assoc = 
  match t with
    | Var s -> s (** avant c'était t ici *)
    | Fun (f,l) -> (**Var*) Fun_map.find (f,l) ack_assoc

let rec flatten_ack l = (* transformer la liste d en conjonction d *)  
  match l with
    | [] -> assert false (* l1 < l2 dans les fold de ackerize2 *)
    | [x] -> x
    | x::y::q -> And(x,flatten_ack (y::q))

let ackerize2_pair f l1 l2 ack_assoc ack_arg =
  let rec aux l1 l2 acc = 
    match (l1,l2) with
      | ([],[]) -> acc
      | (t1::q1,t2::q2) ->
          if t1 = t2 then
            aux q1 q2 acc
          else
            let (s1,s2) = (get_var t1 ack_assoc,get_var t2 ack_assoc) in
            if s1 < s2 then
              aux q1 q2 ((Atom(s1, s2))::acc)
            else
              aux q1 q2 ((Atom (s2, s1))::acc)
      | _ -> assert false in
  let (s1,s2) = (get_var (Fun(f,l1)) ack_assoc,get_var (Fun(f,l2)) ack_assoc) in
  if s1 < s2 then
    Or(Not(flatten_ack (aux l1 l2 [](**???*))),Atom (s1,s2))
  else
    Or(Not(flatten_ack (aux l1 l2 [](**???*))),Atom (s2,s1))
    
let ackerize2 ack_assoc ack_arg =
  flatten_ack 
    (Arg_map.fold
       (fun f list_set l ->
          Arg_set.fold
            (fun l1 l ->
               Arg_set.fold
                 (fun l2 l ->
                    if l1 < l2 then
                      (ackerize2_pair f l1 l2 ack_assoc ack_arg)::l
                    else
                      l)
                 list_set l)
            list_set l)
       ack_arg [])


(** Transformation de Ackermann (ouf !) *)

let ackerize (formula : (t*t) formula_tree) = 
  let (f_ack1,ack_assoc,ack_arg) = ackerize1 formula in
  let f_ack2 = ackerize2 ack_assoc ack_arg in (* une formule sans aucun Fun !!! *)
    (*( *)And(f_ack1,f_ack2)(*,ack_assoc,ack_arg)*)
    
    
let parse lexbuf =
  let raw = Congruence_parser.main Congruence_lexer.token lexbuf in
  ackerize raw
    
let print_atom _ _ = ()
    
