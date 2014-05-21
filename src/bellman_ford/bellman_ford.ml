(*****************************************************************************************************************)
(*                                                                                                               *)
(* Bellman-Ford incrémental                                                                                      *)
(*                                                                                                               *)
(* Ce module fournit une structure incrémentale de graphe avec détection de cycles de poids négatifs via         *)
(* l'algorithme de Bellman-Ford incrémental.                                                                     *)
(*                                                                                                               *)
(* Consulter le fichier README joint pour de plus amples informations. En particulier, les notations utilisées   *)
(*  au cours de l'algorithme sont identiques à celles de [1] (voir Références dans README.md).                   *)
(*                                                                                                               *)
(* [1] Fast and Flexible Difference Constraint Propagation for DPLL(T) (2006) by Scott Cotton, Oded Maler        *)
(*                                                                                                               *)
(*****************************************************************************************************************)

open Braun

module type Equal = sig
  type t
  val eq : t -> t -> bool
  val print : out_channel -> t -> unit
end

module Make(X: Equal) = struct

  module Node = Map.Make(struct type t = X.t let compare = compare end)
  module Heap = Braun.Make(struct type t = int * X.t let le (_,k1) (_,k2) = k1 <= k2 end)

  type t = 
    {
      graph : (int*X.t) list Node.t ; (* voisins de chaque noeud *)
      values : int Node.t ; (* pi <- notation de [1], pareil dans la suite *)
      next_values : int Node.t ; (* pi' *)
      estimate : Heap.t ;  (* gamma *)
      estimate_static : int Node.t ; (* gamma avec lecture en O(1) *)
      explain : (int * X.t) Node.t  (* chemin pour remonter cycle négatif *)
    }

  exception Neg_cycle of X.t * t   

  let empty =     
    { 
      graph = Node.empty ;
      values = Node.empty ;
      next_values = Node.empty ;    
      estimate = Heap.empty ;  
      estimate_static = Node.empty ;
      explain = Node.empty
    }
  
  let add_node v r =
    { r with graph = Node.add v [] r.graph ; values = Node.add v 0 r.values ; next_values = Node.add v 0 r.next_values } 
    
  let add_edge x y c r = (* orienté de x vers y, multi arête *)
    { r with graph = Node.add x ((c,y)::(Node.find x r.graph)) r.graph }
    
  let remove_edge x y c r = (* suppression de la première occurence seulement *)
    let rec aux acc = function
      | [] -> acc
      | (d,u)::q when d=c && u=y -> List.rev_append q acc
      | t::q -> aux (t::acc) q in
    { r with graph = Node.add x (aux [] (Node.find x r.graph)) r.graph }

  (*******)
    
  let init_relaxation u v d r = (* initialisation de gamma *)
    let update = (Node.find u r.values) + d - (Node.find v r.values) in
      let next_values = r.values in
      let explain = if update < 0 then Node.add v (d,u) Node.empty else (*r.explain*) Node.empty in
      let estimate = if update < 0 then Heap.insert (update,v) Heap.empty else Heap.empty in
      let estimate_static = 
        Node.fold (* update sur autre que v, pas ajouté au heap car = 0 *)
          (fun s _ estimate_static -> if s <> v then (Node.add s 0 estimate_static) else estimate_static)
          r.values (Node.add v update Node.empty) in
    { r with estimate = estimate ; estimate_static = estimate_static ; explain = explain ; next_values = next_values }
    
    
  let relax_adjacent s u r = (* relaxer les arêtes partant de s, suite à extraction de u du heap *)   
    let adj = Node.find s r.graph in
    let rec aux l r = match l with
      | [] -> r
      | (c,t)::q -> 
          if (Node.find t r.values) = (Node.find t r.next_values) then
            begin
              let update = (Node.find s r.next_values) + c - (Node.find t r.values) in
              if update < Node.find t r.estimate_static then
                let explain = Node.add t (c,s) r.explain in
                if t = u then (* cycle négatif *)
                   raise (Neg_cycle (u,{r with explain = explain}))
                else
                   aux q { r with estimate = Heap.insert (update,t) r.estimate ; estimate_static = Node.add t update r.estimate_static ; explain = explain }
              else
                aux q r
            end
          else
              aux q r in
    aux adj r

  
  let relax_edge u v d r = 
    let r = init_relaxation u v d r in (* gamma et autres initialisés *)
    let rec aux r =
      try
        let ((k,s),estimate) = Heap.extract_min r.estimate in (* raise si heap vide *) 
        if k = Node.find s r.estimate_static then (* c'est ici qu'on nettoie le heap des doublons non maj *)
          begin
            assert (k < 0 && s <> u); (* on n'insert pas >=0, on détecte u direct, on ne fait que diminuer heap *)
            let next_values = Node.add s ((Node.find s r.values) + k) r.next_values in
            let estimate_static = Node.add s 0 r.estimate_static in
            let r = relax_adjacent s u { r with next_values = next_values; estimate = estimate; estimate_static = estimate_static} in
              aux r
          end
        else
          aux {r with estimate = estimate }
      with
        | Empty -> { r with values = r.next_values } in (* c'est ok : on peut prendre pi' *)
    aux r


  let neg_cycle u r  =  (* construction du cycle nég, que l'on sait exister *)
    let rec insert x l acc = match l with (* insertion sans doublons *)
      | [] -> x::acc
      | t::q -> if t=x then List.rev_append l acc else insert x q (t::acc) in
   let rec aux t acc =
     let (k,s) = Node.find t r.explain in
     if s = u then
       insert (k,s,t) acc []
     else
       aux s (insert (k,s,t) acc []) in
   aux u []

 let print_values p r =  (** ici : renvoyer les -pi *) 
   Node.iter 
     (fun s k -> Printf.fprintf p "%a %d\n" X.print s (-k))
     r.values  
    
end


