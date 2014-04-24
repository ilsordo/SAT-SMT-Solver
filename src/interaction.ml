open Formule
open Clause
open Printf
open Debug
open Algo_base

let str_of_lit (b,v) =
  (if b then "" else "-")^(string_of_int v)

let print_values p (formule:formule) =
  fprintf p "Current values (level) :\n";
  formule#get_paris#iter (fun v b -> fprintf p "%d -> %B (%d)\n" v b (formule#get_level v)) 

let print_graph (formule:formule) (pari,assignations) level clause p =
  (* Indique si une variable (le literal associé) a été vu et si sa cause a été élucidée ainsi que son nom*)
  let seen = new vartable 0 in

  let process conseq uip_found needed b v =
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
        if uip_found then
          fprintf p "%s -> %s\n" tag conseq
        else
          fprintf p "subgraph cluster_0{%s}\n%s -> %s\n" tag tag conseq in

  let explore_clause conseq uip_found needed clause =
    debug#p 2 "Entrée par %s dans la clause : \n%a\n Needed : %B" conseq clause#print () needed;
    clause#get_vpos#iter_all (process conseq uip_found needed true);
    clause#get_vneg#iter_all (process conseq uip_found needed false) in

  let follow_lit (b,v) uip_found needed =
    match formule#get_origin v with
      | None -> assert false (* Tout le monde a une cause dans la tranche *)
      | Some clause ->
          explore_clause (str_of_lit (b,v)) uip_found needed clause;
          seen#set v (true,str_of_lit (not b, v)); in

  let is_uip () =
    debug#p 2 "Analyse de l'uip:\n";
    match seen#fold (fun v (known, tag) (res, count) -> debug#p 2 "%d : %B # %d" v known count;if known then (res, count) else (Some tag, count + 1)) (None, 0) with
      | (Some tag, 1) -> Some tag
      | _ -> None
  in

  let rec explore uip_found = function
    | [] when not uip_found ->
        fprintf p "subgraph cluster_0{%s [penwidth=3,color=goldenrod]}\n" (str_of_lit pari)
    | [] -> ()
    | (b,v) as lit::q ->
        let found =
          match seen#find v with
            | Some (false, my_tag) ->
                let found = 
                  if not uip_found then
                    match is_uip() with
                      | Some tag when tag = my_tag -> (* UIP *)
                          fprintf p "subgraph cluster_0{%s [penwidth=3,color=goldenrod]}\n" tag;
                          true
                      | _ -> (* Post-UIP *)
                          fprintf p "%s [fillcolor=lightseagreen]\n" my_tag;
                          false
                  else
                    begin (* Pre-UIP *)
                      fprintf p "%s [fillcolor=lightseagreen]\n" my_tag;
                      true
                    end in
                follow_lit lit found true;
                found
            | _ -> (* Unrelated *)
                (*fprintf p "%s [fillcolor=lightseagreen,style=dotted]\n" (str_of_lit lit);
                follow_lit lit false;*)
                uip_found in
        explore found q in
  debug#p 2 "Clause conflit : %a\nPari : %s\n%a" clause#print () (str_of_lit pari) print_values formule;
  fprintf p "digraph G{\nrankdir = LR;\nnode[style=filled,shape=circle,width=1];\nsubgraph cluster_0{style=dashed;label=\"Clause\"};\nconflict [label=\"Conflict!\",shape=ellipse,fillcolor=crimson];\n";
  explore_clause "conflict" false true clause;
  explore false assignations;
  fprintf p "%s[fillcolor=chartreuse]\n}\n%!" (str_of_lit pari)
   

let print_resolution (formule:formule) (pari,assignations) level clause =
  ()
 

type interaction =
  | U of (unit -> bool)
  | I of (int -> bool)
  | S of (string -> bool)

class repl step =
  let next = ref step in
object    
  val base_handlers = [
    ('c', U (fun () -> next := Some 1; false), "Continue");
    ('s', I (fun x -> next := Some x; false), "Skip k conflicts");
    ('t', U (fun () -> next := None; false), "Finish execution")]

  method is_ready = 
    match !next with
      | Some 1 ->
          true
      | Some x -> 
          next := Some (x-1);
          false
      | None ->
          false

  method start formule etat (clause:clause) p =
    let rec print_handlers = function
      | [] -> ()
      | (name,_,doc)::q -> 
          fprintf p "%c\t%s\n" name doc;
          print_handlers q in
    let print_graph = match etat.tranches with
      | [] -> assert false
      | tranche::_ -> 
          fun file ->
            try
              let out = open_out (file^".dot") in
              print_graph formule tranche etat.level clause out;
              true
            with 
                Sys_error s -> 
                  fprintf p "Error : %s\n" s;
                  true in
    let print_resolution _ =
      true in
    let print_values () =
      print_values p formule;
      true in
    let handlers =
      ('g',S print_graph,"Print conflict graph to file")
      ::('r',S print_resolution,"Print derivation to file")
      ::('v',U print_values,"Print current values")
      ::base_handlers in
    fprintf p "Conflict on clause %d :\n" clause#get_id;
    print_handlers handlers;
    let rec find_command char = function
      | [] -> None
      | (c,interaction,_)::_ when c = char -> Some interaction
      | _::q -> find_command char q in
    let rec loop = function
      | false -> fprintf p "Resuming execution\n"
      | true ->
          fprintf p "> %!";
          let line = input_line stdin in
          if String.length line > 0 then
            match find_command line.[0] handlers with
              | None -> 
                  fprintf p "Unknown command : %c\n" line.[0]
              | Some interaction -> 
                  let continue = 
                    try 
                      match interaction with
                        | U f -> f()
                        | I f -> Scanf.sscanf line "%_c %d" f
                        | S f -> Scanf.sscanf line "%_c %s" f
                    with
                      | Scanf.Scan_failure s ->
                          fprintf p "Wrong argument\n";
                          true
                      | End_of_file ->
                          fprintf p "Argument required\n";
                          true in
                  loop continue in
    loop true
    
end
