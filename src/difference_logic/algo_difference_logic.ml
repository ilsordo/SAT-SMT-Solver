

type op = Great | Less | LEq | GEq | Eq | Ineq 

type atom = Double of string*string*op*int | Single of string*op*int

let parse_atom s =
  ...
  
let print_atom p a = 
  ...

(* Théorie *)
module String_map = 
struct
  include Map.make(sig type t = string let compare = compare end)
  let find key map =
    try Some (find key map)
    with Not_found -> None
end

type etat = 
  { 
    graph : (int*string) list String_map.t ; (* map de string vers (int*string) list *)
    values : int String_map.t ; (* map de string vers int *)
    explain : atom String_map.t ; (* map de string vers int *)
  }

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
    | Single(s,o,n) -> normalize (Atom (Double(s1,"_zero",o,n)))
  in
    match formula with
      | And (f1,f2) -> And (normalize f1,normalize f2)
      | Or (f1,f2) -> Or (normalize f1,normalize f2)
      | Imp (f1,f2) -> Imp (normalize f1,normalize f2)
      | Equ (f1,f2) -> Equ (normalize f1,normalize f2)
      | Not f -> Not (normalize f)
      | Atom a -> normalize_atom (Atom a) 
  
  
let init reduc = 
  let etat = 
    { 
     graph = String_map.empty;
     values = String_map.empty;
     explain = String_map.empty
    }
  in
    reduc.iter (* Atom a avec a normalisé *)
      (fun a _ ->
         match a with
          | Double (s1,s2,LEq,n) ->
             etat.graph = String_map.add s1 [] etat.graph;  
             etat.graph = String_map.add s2 [] etat.graph;  
             etat.values = String_map.add s1 0 etat.graph;  
             etat.values = String_map.add s2 0 etat.graph
          | _ -> assert false);
     etat (** c'est bon ça ? c'est pas l'ancien état ? *)


let explain_conflict .. = 
  ... avec explain et un noeud de départ >> on remonte
  
let propagate reduc prop etat = 
  let etat_save = etat in (** ça sauve vraiment ça ? *)
  let relax_edge a = (* a de type atom normalisé *)
    match a with
      | Double (s1,s2,LEq,n) ->
          begin
            match (String_map.find s1 etat.values,String_map.find s2 etat.values) with
              | (Some k1,Some k2) -> 
                  if k2 > k1 + n then 
                      begin
                    etat.values = String_map.add s2 (k1 + n) etat.graph;  
                      etat.explain = String_map.add s2 (Double (s1,s2,LEq,n)) etat.explain
                    end
              | _ -> assert false
          end
      | _ -> assert false
  in
  
  (*
    sauvegarder l'état
    tenter de propager
    si ok : ok
    sinon : analyser conflit, restaurer état
  *)
  (* set avec extraction du noeud avec plus grand ? *)
  (* However, it is worth pointing out
that this worst-case complexity bound seldom reflects the performance of the algorithm
in practice *)
  
let backtrack reduc undo_list etat = etat

let print_etat reduc etat = 
  ...
  
let pure_prop = false


