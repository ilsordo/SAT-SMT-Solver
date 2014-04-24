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

(** Graphe *)
let print_graph (formule:formule) (pari,assignations) level (clause:clause) p =
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
    clause#get_vpos#iter_all (process conseq uip_found needed true);
    clause#get_vneg#iter_all (process conseq uip_found needed false) in

  let follow_lit (b,v) uip_found needed =
    match formule#get_origin v with
      | None -> assert false (* Tout le monde a une cause dans la tranche *)
      | Some clause ->
          explore_clause (str_of_lit (b,v)) uip_found needed clause;
          seen#set v (true,str_of_lit (not b, v)); in

  let is_uip () =
    match seen#fold (fun v (known, tag) (res, count) -> if known then (res, count) else (Some tag, count + 1)) (None, 0) with
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
  fprintf p "digraph G{\nrankdir = LR;\nnode[style=filled,shape=circle,width=1];\nsubgraph cluster_0{style=dashed;label=\"Clause\"};\nconflict [label=\"Conflict!\",shape=ellipse,fillcolor=crimson];\n";
  explore_clause "conflict" false true clause;
  explore false assignations;
  fprintf p "%s[fillcolor=chartreuse]\n}\n%!" (str_of_lit pari)


(** Resolution *)
type split_clause = (literal list*literal list*literal) 

type proof = Tag of int | Base of split_clause*int | Resol of proof*split_clause*split_clause*int

let print_resolution (formule:formule) (pari,assignations) level clause p =
  
  let print_lit p (b,v) =
    if b then
      fprintf p "\\varv{%d}" v
    else
      fprintf p "\\varf{%d}" v in

  (*let print_raw_clause p = function
    | [] -> assert false (* Que fait une clause vide ici? *)
    | t::q ->
    print_lit p t;
    List.iter (fun lit -> fprintf p "\\lor %a" print_lit lit) q in*)

  let print_split_clause p (lower,curr,join) =
    let started =
      match lower with
        | [] -> false
        | t::q -> 
            print_lit p t;
            List.iter (fun lit -> fprintf p "\\lor %a" print_lit lit) q;
            true in
    let started =
      match curr with
        | l when started ->
            List.iter (fun lit -> fprintf p "\\lor {\\color{blue} %a}" print_lit lit) l;
            true
        | [] -> false
        | t::q -> 
            fprintf p "{\\color{blue} %a}" print_lit t;
            List.iter (fun lit -> fprintf p "\\lor {\\color{blue} %a}" print_lit lit) q;
            true in
    if started then
      fprintf p "\\lor ";
    fprintf p "{\\color{red} %a}\n%!" print_lit join in
  
  let print_proof proof_id proof =
    let rec aux p = function
      | Tag i ->
          fprintf p "\\preuve{%d}\n" i
      | Base (c,id) ->
          fprintf p "\\cl{%d} %a\n" id print_split_clause c
      | Resol (proof,conclusion,clause,id) ->
          fprintf p "\\inferrule{\n%a\\and\n\\cl{%d} %a}{\n%a}\n" 
            aux proof 
            id 
            print_split_clause clause
            print_split_clause conclusion in
    fprintf p "\\begin{mathpar}\\preuve{%d}:~%a\\end{mathpar}\n" proof_id aux proof in
  
  let split_clause ((b_join,v_join) as join) (clause:clause) =
    let aux b v (lower,curr) =
      if (b,v) = join then
        (lower,curr)
      else
        if formule#get_level v = level then
          (lower,(b,v)::curr)
        else
          ((b,v)::lower,curr) in
    assert(v_join = 0 || clause#mem_all b_join v_join); (** Horreur nécessaire *)
    let (lower,curr) = clause#get_vpos#fold_all (aux true) (clause#get_vneg#fold_all (aux false) ([],[])) in
    (List.sort compare lower,List.sort compare curr) in

  let resol (lower,curr,(b,v)) (clause:clause) =
    let simplify x = function (* Pour un fold_right uniquement *)
      | t::q when x = t -> q
      | l -> x::l in
    let (lower',curr') = split_clause (not b,v) clause in
    let lower = List.(fold_right simplify (merge compare lower lower') []) in
    let curr = List.(fold_right simplify (merge compare curr curr') []) in
    (lower,curr) in

  let rec find_next curr = function
    | [] -> assert false
    | (b,v)::q when List.mem (b, v) curr -> ((b,v),q)
    | _::q -> find_next curr q in
  

  let rec build_proof proof (lower,curr,(b,v)) remaining =
    match curr with
      | [] -> print_proof 1 proof
      | _ ->
          let clause =
            match formule#get_origin v with
              | None -> assert false
              | Some clause -> clause in 
          let (lower',curr') = resol (lower,curr,(not b, v)) clause in
          let (join,remaining) = find_next curr' remaining in
          let conclusion = (lower',List.filter ((<>) join ) curr',join) in (* Join the Empire? *)
          build_proof (Resol(proof,conclusion,(lower',curr',(not b, v)),clause#get_id)) conclusion remaining in
  debug#p 0 "%d" level;
  fprintf p "
\\documentclass{article}
\\usepackage{mathpartir}
\\usepackage[utf8]{inputenc}
\\usepackage{color}
\\newcommand{\\non}[1]{\\overline{#1}}
\\newcommand{\\varv}[1]{x_{#1}}
\\newcommand{\\varf}[1]{\\non{\\varv{#1}}}
\\newcommand{\\cl}[1]{\\mathtt{C_{#1}:~}}
\\newcommand{\\preuve}[1]{\\mathtt{\\Pi_{#1}}}
\\begin{document}
Preuve de résolution :";
  let (lower,curr) = split_clause (false,0) clause in
  let (join,remaining) = find_next curr assignations in
  let init = (lower,List.filter ((<>) join ) curr,join) in
  build_proof (Base(init,clause#get_id)) init remaining;
  fprintf p "\\end{document}\n%!"
  
(** Boucle *)

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
    let print_graph =
      match etat.tranches with
        | [] -> assert false
        | tranche::_ -> 
            fun file ->
              try
                let out = open_out (file^".dot") in
                print_graph formule tranche etat.level clause out;
                fprintf p "Output written to %s, view it with ./print_graph %s\n" (file^".dot") file;
                true
              with 
                  Sys_error s -> 
                    fprintf p "Error : %s\n" s;
                    true in
    let print_resolution =
      match etat.tranches with
        | [] -> assert false
        | tranche::_ -> 
            fun file ->
              try
                let out = open_out (file^".tex") in
                print_resolution formule tranche etat.level clause out;
                fprintf p "Output written to %s, view it with ./print_resol %s\n" (file^".tex") file;
                true
              with 
                  Sys_error s -> 
                    fprintf p "Error : %s\n" s;
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
