open Formule
open Clause
open Printf
open Debug

let str_of_lit (b,v) =
  (if b then "" else "-")^(string_of_int v)

let print_valeurs p (formule:formule) =
  fprintf p "Valeurs assignées :\n";
  formule#get_paris#iter (fun v b -> fprintf p "%d -> %s (%d)\n" v (if b then "True" else "False") (formule#get_level v)) 

(* Il faudrait connaitre état ... on verra plus tard *)
let print_graph (formule:formule) (pari,assignations) level p clause =
  (* Indique si une variable (le literal associé) a été vu et si sa cause a été élucidée ainsi que son nom*)
  let seen = new vartable 0 in

  let process conseq b v =
    if str_of_lit (b,v) <> conseq then
      let tag = str_of_lit (not b,v) in
      let l = formule#get_level v in
      if l = level then
        begin
          if seen#mem v = false then 
            seen#set v (false,tag);
          fprintf p "%s -> %s\n" tag conseq
        end
      else
        fprintf p "%s -> %s\n" tag conseq in

  let explore_clause conseq clause =
    debug#p 2 "Entrée par %s dans la clause : \n%a" conseq clause#print ();
    clause#get_vpos#iter_all (process conseq true);
    clause#get_vneg#iter_all (process conseq false) in

  let follow_lit (b,v) =
    fprintf p "%s [fillcolor=lightseagreen]\n" (str_of_lit (b,v));
    seen#set v (true,str_of_lit (not b, v));
    match formule#get_origin v with
      | None -> assert false (* Tout le monde a une cause *)
      | Some clause -> 
          explore_clause (str_of_lit (b,v)) clause in

  let is_uip () =
    debug#p 2 "Analyse de l'uip:\n";
    match seen#fold (fun v (known, tag) (res, count) -> debug#p 2 "%d : %B" v known;if known then (res, count) else (Some tag, count + 1)) (None, 0) with
      | (Some tag, 1) -> Some tag
      | _ -> None
  in

  let rec explore uip_found = function
    | [] -> ()
    | lit::q ->
        let found = if not uip_found then
            match is_uip() with
              | Some tag -> 
                  fprintf p "%s [fillcolor=gold]\n" tag;
                  true
              | None -> 
                  false
          else 
            true in
        follow_lit lit;
        explore found q in
  debug#p 2 "Clause conflit : %a\nPari : %s\n%a" clause#print () (str_of_lit pari) print_valeurs formule;
  fprintf p "digraph G{\nrankdir = LR;\nnode[style=filled,shape=circle];\nconflict [label=\"Conflict!\",shape=ellipse,fillcolor=crimson];\n";
  explore_clause "conflict" clause;
  explore false assignations;
  fprintf p "%s[fillcolor=chartreuse]\n}\n%!" (str_of_lit pari)
        
    


(** Note : il faut regarder quelles clauses sont utiles! *)















