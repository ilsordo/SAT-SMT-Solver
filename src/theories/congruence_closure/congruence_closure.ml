open Formula_tree
open Union_find
open Congruence_type

type term = Congruence_type.t

include Equality

module Fun_map = Map.Make(struct type t = string * (term list) let compare = compare end) (* associe le string f(x1,...,xn) à f(x1,...,xn) *)
module Arg_map = Map.Make(struct type t = string let compare = compare end) (* va associer à chaque symbole de fonction s l'ensemble des (x1,...xn) tq on ait f(x1,...xn) quelque part *)
module Arg_set = Set.Make(struct type t = term list let compare = compare end) (* ensemble des (x1...xn) définit ci-dessus *)

(* La congruence closure s'appuie intégralement sur l'égalité.
   Toute formule contenant des symboles des symboles de fonction est transformée en une formule sans symboles de fonctions grâce à la transformation d'Ackermann.
   Le fichier actuel contient l'implémentation de la transformation d'Ackermann.
   
   Quelques références sur cette transformation : 
     [1] Satisfiability Checking. Equalities and Uninterpreted Functions by Erika Abraham
     [2] To Ackermann-ize or not to Ackermann_ize ? On Efficiently Handling Uninterpreted Function Symbols in SMT(EUF_UT) (2006) by Roberto Bruttomesso, Alessandro Cimatti, Anders Franzén, Alberto Griggio, Alessandro Santuari, Roberto Sebastiani.
    
*)


(** Transformation 1 : remplacer les termes et sous termes par des variables fraiches (inutile de le faire pour les variables) *)

let add_set f l ack_arg = (* ajouter l dans le set associé à f *) 
  let set =
    try
      Arg_map.find f ack_arg
    with
      | Not_found -> Arg_set.empty in
  Arg_map.add f (Arg_set.add l set) ack_arg

let rec term_to_string t = match t with
  | Var s -> s
  | Fun(f,l) -> 
      begin
        match l with
          | [] -> f^"()" 
          | [x] -> f^"("^(term_to_string x)^")" 
          | t::q -> f^"("^(List.fold_left (fun s arg -> s^","^(term_to_string arg)) (term_to_string t) q)^")"
      end
  
  
let rec ackerize1_term t free ack_assoc ack_arg = (* transformer un terme *)
  match t with
    | Var s -> (s, free, ack_assoc, ack_arg)
    | Fun (f,l) -> 
        try
          (Fun_map.find (f,l) ack_assoc, free, ack_assoc, ack_arg)
        with
          | Not_found -> 
              let s = (term_to_string t) in
              let ack_assoc = Fun_map.add (f,l) s ack_assoc in
              let ack_arg = add_set f l ack_arg in
              let (l_ack,free,ack_assoc,ack_arg) = ackerize1_list l (free+1) ack_assoc ack_arg [] in
                (s, free, ack_assoc, ack_arg)


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
    | Var s -> s
    | Fun (f,l) -> Fun_map.find (f,l) ack_assoc

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
      | _ -> 
         Printf.eprintf "Arity mismatch in function %s\n%!" f; 
         exit 1 in
  let (s1,s2) = (get_var (Fun(f,l1)) ack_assoc,get_var (Fun(f,l2)) ack_assoc) in
  if s1 < s2 then
    Or(Not(flatten_ack (aux l1 l2 [])),Atom (s1,s2))
  else
    Or(Not(flatten_ack (aux l1 l2 [])),Atom (s2,s1))
    
let ackerize2 ack_assoc ack_arg f_ack1 =
  match
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
  with
    | [] -> f_ack1
    | l -> And(f_ack1,flatten_ack l)

(** Transformation de Ackermann (ouf !) *)

let ackerize (formula : (t*t) formula_tree) = 
  let (f_ack1,ack_assoc,ack_arg) = ackerize1 formula in
  ackerize2 ack_assoc ack_arg f_ack1 (* une formule sans aucun Fun !!! *)
    
    
let parse lexbuf =
  try
    let raw = Congruence_parser.main Congruence_lexer.token lexbuf in
    ackerize raw
  with
      | Failure _ | Congruence_parser.Error ->
          Printf.eprintf "Input error\n%!";
          exit 1

let print_atom _ _ = ()
    
