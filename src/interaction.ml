open Formule
open Clause
open Printf

let str_of_lit (b,v) =
  (if b then "" else "-")^(string_of_int v)

(* Aplatit une liste de liste, mélange tout mais c'est pas grave *)
let rec super_flatten acc = function
  | [] -> acc
  | l::q -> super_flatten (List.rev_append l acc) q

let print_graph p formule clause level =
(* C'est pas très beau et ça demande à être testé ... *)
  let seen = new vartable 0 in
  let process conseq b v acc =
    if str_of_lit (b,v) = conseq then
      acc
    else
      begin
        let tag = str_of_lit (not b,v) in
        match formule#get_level v with
          | None -> assert false (* Probablement pas normal, nos clauses sont saturées en conflit je crois *)
          | Some l when l = level ->
              let r = if seen#mem v = None then
                  begin
                    fprintf p "%s [fillcolor=lightseagreen]\n" tag;
                    seen#set v ();
                    (not b,v)::acc
                  end
                else
                  acc in
              fprintf p "%s -> %s\n" tag conseq;
              r
          | Some l ->
              fprintf p "%s -> %s\n" tag conseq;
              acc
      end in

  let split_clause conseq clause =
    clause#get_vpos#fold_all (process conseq true) (clause#get_vneg#fold_all (process conseq false) acc) [] in

  let follow_lit (b,v) =
    match formule#get_origin v with
      | None -> []
      | Some clause -> split_clause (str_of_lit (b,v)) clause in

  let rec explore uip_found = function
    | [] -> ()
    | [lit] when not uip_found ->
        fprintf p "%a [fillcolor=gold]\n" print_lit lit;
        explore false [lit]
    | l -> explore uip_found (super_flatten (List.rev_map follow_lit l)) in
  fprintf p "digraph G{\nrankdir = LR;\nsize ="4,4";\nnode[style=filled,shape=circle];\nconflict [label=\"Conflict!\",shape=ellipse,fillcolor=crimson];\n";
  explore false (split_clause "conflit" clause);
  fprintf "\n%!"
        
    


















