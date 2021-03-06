open Printf
open Reduction

exception Illegal_variable_name of string

type 'a formula_tree =
  | And of ('a formula_tree)*('a formula_tree) 
  | Or of ('a formula_tree)*('a formula_tree)  
  | Imp of ('a formula_tree)*('a formula_tree) (* implication *)
  | Equ of ('a formula_tree)*('a formula_tree) (* équivalence *)
  | Not of ('a formula_tree) 
  | Atom of 'a

let rec print_formule print_atom p = function
  | Atom a -> fprintf p "%a" print_atom a
  | Not f -> fprintf p "Not(%a)" (print_formule print_atom) f
  | And(f,g) -> fprintf p "(%a)/\\(%a)" (print_formule print_atom) f (print_formule print_atom) g
  | Or(f,g) -> fprintf p "(%a)\\/(%a)" (print_formule print_atom) f (print_formule print_atom) g
  | Imp(f,g) -> fprintf p "(%a)->(%a)" (print_formule print_atom) f (print_formule print_atom) g
  | Equ(f,g) -> fprintf p "(%a)<->(%a)" (print_formule print_atom) f (print_formule print_atom) g

let rec convert parse_atom = function
  | Atom a -> parse_atom a
  | Not f -> Not (convert parse_atom f)
  | And(f,g) -> And (convert parse_atom f, convert parse_atom g)
  | Or(f,g) -> Or (convert parse_atom f, convert parse_atom g)
  | Imp(f,g) -> Imp (convert parse_atom f, convert parse_atom g)
  | Equ(f,g) -> Equ (convert parse_atom f, convert parse_atom g)

let to_cnf t_formule = (* construit la cnf, en utilisant des variables fraiches // transformation de Tseitin *)
  let fresh = new counter 1 (fun i -> Virtual i) in (* générateur de variables fraiches successives *)
  let impl x1 x2 = [(false,x1);(true,x2)] in (* Raccourci *)
  let rec aux cnf = function (* le label peut être imposé par un connecteur ou laissé au choix *)
    | [] -> cnf
    | (f, label)::q ->
        let cnf, formule = match f with
          | Atom v ->
              ((impl label (Real v))::(impl (Real v) label)::cnf), q
          | Not f ->
              let l1 = fresh#next in
              ([(false,label);(false,l1)]::[(true,label);(true,l1)]::cnf), ((f,l1)::q)
          | And(f,g) ->
              let l1 = fresh#next in
              let l2 = fresh#next in
              ([(true,label);(false,l1);(false,l2)]::(impl label l1)::(impl label l2)::cnf), ((f,l1)::(g,l2)::q)
          | Or(f,g) ->
              let l1 = fresh#next in
              let l2 = fresh#next in
              ([(false,label);(true,l1);(true,l2)]::(impl l1 label)::(impl l2 label)::cnf), ((f,l1)::(g,l2)::q)
          | Imp(f,g) ->
              cnf, ((Or(Not f, g), label)::q)
          | Equ(f,g) -> 
              cnf, (((And(Imp(f,g),Imp(g,f))), label)::q) in
        aux cnf formule in
  let label = fresh#next in
  let res = [true,label]::(aux [] [t_formule, label]) in
  (res,fresh#count + 2 )
  
  
