open Bellman_ford
open Formula_tree

type atom = Double of string*string*op*int | Single of string*op*int

let parse_atom s =
  ...
  
let print_atom p a = 
  ...

module Graph = Bellman_ford.Make(struct type t = string let eq a b = (a = b) end)

type etat = Graph.t


(** Normalisation *)

let rec normalize formula = 
  let rec normalize_atom = function
    | Double (s1,s2,o,n) ->
        begin
          match o with
            | Great -> normalize (Atom (Double(s2,s1,Leq,-n-1))) 
            | Less -> normalize (Atom (Double(s1,s2,Leq,n-1))) 
            | LEq -> if s2 > s1 then Not (Atom (Double(s2,s1,Leq,n-1))) else Atom (Double(s1,s2,Leq,n))
            | GEq -> normalize (Atom (Double(s2,s1,Leq,-n)))  
            | Eq -> And(normalize (Atom (Double(s1,s2,Leq,n))),normalize (Atom (Double(s2,s1,Leq,-n))))
            | Ineq -> Not(normalize (Atom (Double(s1,s2,Eq,n))))
        end
    | Single(s,o,n) -> normalize (Atom (Double(s1,"_zero",o,n))) in (** bien gérer ce _zero après, ne pas l'afficher... *)
  match formula with
    | And (f1,f2) -> And (normalize f1,normalize f2)
    | Or (f1,f2) -> Or (normalize f1,normalize f2)
    | Imp (f1,f2) -> Imp (normalize f1,normalize f2)
    | Equ (f1,f2) -> Equ (normalize f1,normalize f2)
    | Not f -> Not (normalize f)
    | Atom a -> normalize_atom a
  
  
(** Initialisation *)

let init reduc = 
  reduc#fold (* Atom a avec a normalisé *)
    (fun a _ etat ->
       match a with
         | Double (s1,s2,LEq,n) when s1 < s2 -> Graph.add_node s2 (Graph.add_node s1 etat)
         | _ -> assert false)
    Graph.empty


(** Propagation *)

let propagate_unit (b,v) reduction etat = 
  match reduction#get_orig v with
    | None -> etat
    | Some a -> 
        begin
          match a with
            | Double (s1,s2,LEq,n) when s1 < s2 -> 
                if b then
                  Graph.relax_edge s1 s2 n (Graph.add_edge s1 s2 n)
                else
                  Graph.relax_edge s2 s1 (-n-1) (Graph.add_edge s2 s1 (-n-1)) (***)
            | _ -> assert false
        end
          

let get_neg_cycle l reduction = 
  let id (k,s1,s2) =
    match (reduction#get_id (Double (s1,s2,LEq,k)),reduction#get_id (Double (s2,s1,LEq,-(k+1)))) with
      | (Some v,_) -> (true,v) (***)
      | (_,Some v) -> (false,v) in
  List.fold_left (fun res t -> (id t)::res ) [] l  (** attention doublons *)


let propagate reduction prop etat = (* propagation tout-en-un *)                        
  List.fold_left 
    (fun etat l -> 
       try
         propagate_unit l reduction etat
       with
         | Graph.Neg_cycle(s,etat) -> raise Conflit_smt(get_neg_cycle (neg_cycle s etat) reduction, etat))
    etat prop
      
        
(** Backtrack *)
  
let backtrack_unit (b,v) reduction etat = 
  match reduction#get_orig v with
    | None -> etat
    | Some a -> 
        begin
          match a with
            | Double (s1,s2,LEq,n) when s1 < s2 -> 
                if b then
                  Graph.remove_edge s1 s2 n etat
                else
                  Graph.remove_edge s2 s1 -(n+1) etat (***)
            | _ -> assert false
        end
        
         
let backtrack reduction undo_list etat =
  List.fold_left (fun etat l -> backtrack_unit l reduction etat) etat undo_list


(** Affichage du résultat *)

let get_answer _ etat _ p = 
  etat.print_values p ...

  
let pure_prop = false




