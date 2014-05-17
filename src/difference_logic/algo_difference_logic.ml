

type op = Great | Less | LEq | GEq | Eq | Ineq 

type atom = Double of string*string*op*int | Single of string*op*int



let parse_atom s =
  ...
  
let print_atom p a = 
  ...


module String_map = 
struct
  include Map.make(sig type t = string let compare = compare end)
  let find key map =
    try Some (find key map)
    with Not_found -> None
end
  
module Heap = Braun.Make(struct type t = (string*int) let le (s1,k1) (s2,k2) = k1 <= k2 end)

type etat = 
  { 
    graph : (int*string) list String_map.t ;
    values : int String_map.t ; (* pi *)
    next_values : int String_map.t (* pi' *)
    estimate : Heap.t ;  (* gamma *)
    estimate_static : int String_map.t (* gamma*)
    explain : atom String_map.t ; (* chemin *)
  }

exception Neg_cycle of etat


(** Normalisation *)

let rec normalize formula = 
  let rec normalize_atom (Atom a) = match a with
    | Double(s1,s2,o,n) ->
        begin
          match o with
            | Great -> normalize (Atom (Double(s2,s1,Leq,-n-1))) 
            | Less -> normalize (Atom (Double(s1,s2,Leq,n-1))) 
            | LEq -> if s2 > s1 then Not (Atom (Double(s2,s1,Leq,n-1))) else Atom (Double(s1,s2,Leq,n))
            | GEq -> normalize (Atom (Double(s2,s1,Leq,-n)))  
            | Eq -> And(normalize (Atom (Double(s1,s2,Leq,n))),normalize (Atom (Double(s2,s1,Leq,-n))))
            | Ineq -> Not(normalize (Atom (Double(s1,s2,Eq,n))))
        end
    | Single(s,o,n) -> normalize (Atom (Double(s1,"_zero",o,n))) (** bien gérer ce _zero apès... *)
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
  let etat = 
    { 
     graph = String_map.empty;
     values = String_map.empty; (* pi *)
     next_values = String_map.empty (* pi' *)    
     estimate = Heap.empty ;  (* gamma *)
     estimate_static = String_map.empty ; (* gamma *)
     explain = String_map.empty;
    }
  in
    reduc.fold (* Atom a avec a normalisé *)
      (fun a _ etat ->
         match a with
          | Double (s1,s2,LEq,n) when s1 < s2 ->
             let graph = String_map.add s1 [] (String_map.add s2 [] etat.graph) in
             let values = String_map.add s1 0 (String_map.add s2 0 etat.values) in
             let next_values = String_map.add s1 0 (String_map.add s2 0 etat.next_values) in
             { etat with graph = graph ; values = values ; next_values = next_values}
          | _ -> assert false) (* ici, et pour les matching similaires qui suivent : aurait du être normalisé *)
     etat


(** Propagation *)
 
let add_edge e etat = (* multi-arêtes : peut-être que c'est faux ... *)
  match e with
    | Double(u,v,LEq,c) when u < v ->
        {etat with graph = String_map.add u ((c,v)::(String_map.find u etat.graph )) etat.graph}
    | _ -> assert false
 
let remove_edge e etat = 
  let rec aux v c adj acc = match adj with
    | [] -> acc
    | (d,u)::q when u=v && d=c -> List.rev_append q acc
    | t::q -> aux v c q (t::acc) in
  match e with
    | Double(u,v,LEq,c) when u < v ->
        {etat with graph = String_map.add u (aux v c (String_map.find u etat.graph) []) etat.graph}
    | _ -> assert false    
 
let init_estimate u v c etat = (* initialisation de gamma *)
  let (estimate,estimate_static) = 
    String_map.fold
      (fun s _ (estimate,estimate_static) -> if s <> v then (Heap.insert (s,0) estimate, String_map.add s 0 estimate_static) else (estimate,estimate_static))
      (let update = (String_map.find u etat.values) + c - (String_map.find v etat.values) in
        (Heap.insert (v,update) etat.estimate, String_map.add v update etat.estimate_static))
    in   
  { etat with estimate = estimate ; estimate_static = estimate_static }
               
let propagate_estimate s etat = (* relaxation sur arêtes adjacentes *)
  let adj = String_map.find s etat.graph in
  let rec aux l etat = match l with
    | [] -> etat
    | (d,t)::q -> 
        if (String_map.find t etat.values) = (String_map.find t etat.next_values) then
          begin
            let update = (String_map.find s etat.next_values) + d - (String_map.find t etat.values) in
            if update < 0 && t = u then (* cycle négatif *)
              raise Neg_cycle {etat with explain = String_map.add u Double(s,u,LEq,d) etat.explain}
            else if update < String_map.find t etat.estimate_static then
              aux q { etat with estimate = Heap.insert(***) (t,update) etat.estimate ; estimate_static = String_map.add t update etat.estimate_static ; explain = String_map.add t Double(s,t,LEq,d) etat.explain} (** peut être à généraliser lors du non refinement *)
          end
        else
          aux q etat
  in
    aux adj etat
      
let relax_edge a etat = (* relaxation complète d'une arête *)
  match a with
    | Double (u,v,LEq,c) when u < v ->
        begin
          let rec aux etat =
            let ((s,k),estimate) = Heap.extract_min estimate in (* ça ne doit pas raise *)
              if k<0 && String_map.find s estimate_static = k then (** c'est ici qu'on nettoie le heap des doublons non maj *)
                let next_values = String_map.add s ((String_map.find s etat.values) + k) etat.next_values in
                let estimate = Heap.insert (s,0) estimate in
                let estimate_static = String_map.add s 0 estimate static in
                let etat = propagate_estimate s {etat with next_values = next_values; estimate=estimate; estimate_static = estimate_static} in (* peut lever neg_cycle *)
                  aux etat
              else
                etat
          in            
          aux (init_estimate u v c etat)
        end
    | _ -> assert false

let explain_conflict a reduc etat =  (* construction du cycle nég, que l'on sait exister *)
  let insert x l acc = match l with (* insertion sans doublons *)
    | [] -> x::acc
    | t::q -> if t=x then List.rev_append (t::q) acc else insert x q (t::acc) in
  let rec aux u v acc =
    match String_map.find v etat.explain
      | (Double(s,t,LEq,d) as a) when t = v && s < t ->
          begin
            match reduc.get_id a with
              | None -> assert false
              | Some l -> l::acc
                  if s = u then
                    insert l acc []
                  else
                    aux u s (insert l acc [])
      | _ assert false
  in match a with 
    | Double (u,v,LEq,c) when u < v -> aux u u []
    | _ -> assert false
  
let propagate reduction prop etat = (* propagation tout-en-un *)
  let rec aux prop etat = match prop with
    | [] -> { etat with etat.values = etat.next_values } (* on update values car no conflit *)
    | l::q ->
        begin 
          match reduc.get_orig l with
            | None -> aux q etat
            | Some a -> 
                try 
                  aux q (relax_edge a (add_edge a etat))
                with
                  begin
                    | Empty -> assert false (* heap vide *)
                    | Neg_cycle etat ->
                        raise Conflit_smt (explain_conflict a reduction etat,etat) 
                  end
        end
   
  (** mise à jour explain qd gamma refined *)
  (** on ajoute qd les aretes *)
  (** vérifier dimin min heap *)
  
(** Backtrack *)
  
let backtrack reduc undo_list etat =
  let rec aux etat = function
    | [] -> etat
    | l::q ->
        begin
          match reduc.get_orig l with
            | None -> aux etat q
            | Some a -> aux (remove_edge a etat) q
        end
  in
    aux etat undo_list   


let print_etat reduc etat = (** ici : renvoyer les -pi *) 
  ...
  
let pure_prop = false


