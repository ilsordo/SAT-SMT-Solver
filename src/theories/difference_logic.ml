open Bellman_ford
open Formula_tree
open Clause
open Debug

type atom = string*string*int (* s1 - s2 <= n avec s1 < s2 (comparaison sur string) *)


let print_atom p (s1,s2,n) = Printf.fprintf p "%s - %s <= %d" s1 s2 n

let parse lexbuf =
  try
    let raw = Difference_parser.main Difference_lexer.token lexbuf in
    print_formule print_atom stdout raw;
    raw
  with
    | Failure _ | Difference_parser.Error ->
        Printf.eprintf "Input error\n%!";
        exit 1

module Graph = Bellman_ford.Make (struct type t = string let eq a b = (a = b) let print p k = Printf.fprintf p "%s" k end)

type etat = Graph.t

exception Conflit_smt of (literal list*etat)
  
(** Initialisation *)

let init (reduc : atom Reduction.reduction) = 
  reduc#fold
    (fun (s1,s2,n) _ etat ->
      Graph.add_node s2 (Graph.add_node s1 etat))
    Graph.empty


(** Propagation *)

let propagate_unit (b,v) reduction etat = 
  match reduction#get_orig v with
    | None -> etat
    | Some (s1,s2,n) -> 
        if b then
          (assert false;debug#p 2 "graph %s %s %d" s1 s2 n; 
          Graph.relax_edge s1 s2 n (Graph.add_edge s1 s2 n etat))
        else
         (assert false;debug#p 2 "graph %s %s %d" s2 s1 (-n-1); 
          Graph.relax_edge s2 s1 (-n-1) (Graph.add_edge s2 s1 (-n-1) etat)) (***)
          

let get_neg_cycle l reduction = 
  let id (k,s1,s2) =
    match (reduction#get_id (s1,s2,k),reduction#get_id (s2,s1,-(k+1))) with
      | (Some v,_) -> (false,v) (***** inversion des args !!!*)
      | (_,Some v) -> (true,v)
      | (None, None) -> assert false in
  List.fold_left (fun res t -> (id t)::res ) [] l  (** attention doublons *)


let propagate reduction prop etat = (* propagation tout-en-un *)                        
  List.fold_left 
    (fun etat l -> 
       try
         propagate_unit l reduction etat
       with
         | Graph.Neg_cycle(s,etat) -> raise (Conflit_smt (get_neg_cycle (Graph.neg_cycle s etat) reduction, etat)))
    etat prop
      
        
(** Backtrack *)
  
let backtrack_unit (b,v) reduction etat = 
  match reduction#get_orig v with
    | None -> etat
    | Some (s1,s2,n) -> 
        if b then
          Graph.remove_edge s1 s2 n etat
        else
          Graph.remove_edge s2 s1 (-n-1) etat (***)
        
         
let backtrack reduction undo_list etat =
  List.fold_left (fun etat l -> backtrack_unit l reduction etat) etat undo_list


(** Affichage du résultat *)

let print_answer _ etat _ p = 
  Graph.print_values "_phantom" p etat

  
let pure_prop = false
