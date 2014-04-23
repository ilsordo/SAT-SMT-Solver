open Formule
open Clause
open Printf
open Debug
open Algo_base

type interaction =
  | U of (out_channel -> bool)
  | I of (int -> out_channel -> bool)
  | S of (string -> out_channel -> bool)


let str_of_lit (b,v) =
  (if b then "" else "-")^(string_of_int v)

let print_valeurs p (formule:formule) =
  fprintf p "Valeurs assignées :\n";
  formule#get_paris#iter (fun v b -> fprintf p "%d -> %B (%d)\n" v b (formule#get_level v)) 

(* Il faudrait connaitre état ... on verra plus tard *)
let print_graph (formule:formule) (pari,assignations) level p clause =
  (* Indique si une variable (le literal associé) a été vu et si sa cause a été élucidée ainsi que son nom*)
  let seen = new vartable 0 in

  let process conseq needed b v =
    if str_of_lit (b,v) <> conseq then
      let tag = str_of_lit (not b,v) in
      let l = formule#get_level v in
      if l = level then
        begin
          if seen#mem v = false then
            if needed then 
              seen#set v (false,tag) (* Il faudra en trouver la cause *) 
            else
              seen#set v(true,tag); (* On fait comme si on connaissait déjà la cause *)
          fprintf p "%s -> %s\n" tag conseq
        end
      else
        fprintf p "%s -> %s\n" tag conseq in

  let explore_clause conseq needed clause =
    debug#p 2 "Entrée par %s dans la clause : \n%a\n Needed : %B" conseq clause#print () needed;
    clause#get_vpos#iter_all (process conseq needed true);
    clause#get_vneg#iter_all (process conseq needed false) in

  let follow_lit (b,v) needed =
    match formule#get_origin v with
      | None -> assert false (* Tout le monde a une cause dans la tranche *)
      | Some clause ->
          explore_clause (str_of_lit (b,v)) needed clause;
          seen#set v (true,str_of_lit (not b, v)); in

  let is_uip () =
    debug#p 2 "Analyse de l'uip:\n";
    match seen#fold (fun v (known, tag) (res, count) -> debug#p 2 "%d : %B # %d" v known count;if known then (res, count) else (Some tag, count + 1)) (None, 0) with
      | (Some tag, 1) -> Some tag
      | _ -> None
  in

  let rec explore uip_found = function
    | [] -> ()
    | (b,v) as lit::q ->
        let found =
          match seen#find v with
            | Some (false, my_tag) ->
                let found = 
                  if not uip_found then
                    match is_uip() with
                      | Some tag when tag = my_tag -> (* UIP *)
                          fprintf p "%s [fillcolor=gold]\n" tag;
                          true
                      | _ -> (* Post-UIP *)
                          fprintf p "%s [fillcolor=purple]\n" my_tag;
                          false
                  else
                    begin (* Pre-UIP *)
                      fprintf p "%s [fillcolor=lightseagreen]\n" my_tag;
                      true
                    end in
                follow_lit lit true;
                found
            | _ -> (* Unrelated *)
                fprintf p "%s [fillcolor=lightsalmon4]\n" (str_of_lit lit);
                follow_lit lit false;
                uip_found in
        explore found q in
  debug#p 2 "Clause conflit : %a\nPari : %s\n%a" clause#print () (str_of_lit pari) print_valeurs formule;
  fprintf p "digraph G{\nrankdir = LR;\nnode[style=filled,shape=circle];\nconflict [label=\"Conflict!\",shape=ellipse,fillcolor=crimson];\n";
  explore_clause "conflict" true clause;
  explore false assignations;
  fprintf p "%s[fillcolor=chartreuse]\n}\n%!" (str_of_lit pari)
        
(*
['g',`Unit (fun () -> draw_graph ... ), "Affiche le graphe"]

(c,form,doc) when c = char ->
match form with
  | Unit of fun -> 
*)
