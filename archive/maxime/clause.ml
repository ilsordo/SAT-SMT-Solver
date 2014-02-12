type var = int

type lit = bool*var

type clause = lit list

type cnf = clause list

type input = (int*int*cnf)

(* On trie les litéraux par variable décroissante puis par positivité *)
let cmp (b1,v1) (b2,v2) = match -(compare v1 v2) with
  | 0 -> compare b1 b2
  | x -> x

(* Supprime les doublons d'une liste triée *)
let simplify l = 
  let rec aux acc = function
    | [] -> List.rev acc
    | a::(b::q as l) when a=b -> aux acc l
    | a::q -> aux (a::acc) q in
  aux [] l

(* Trie et enlève les doublons des clauses *)
let make l =
  simplify (List.sort cmp l)

(* Concaténation de clauses, on supprime aussi les variables apparaissant à la fois de manière positive et négative *)
let merge c1 c2 =
  simplify (List.merge cmp c1 c2)

let print_lit p (b,x) =
  if not b then Printf.fprintf p "-";
  Printf.fprintf p "%d " x

let print_clause p = function
  | [] -> Printf.fprintf p "Clause vide"
  | l ->
      List.iter (print_lit p) l

let print_cnf p = function
  | [] -> Printf.fprintf p "c cnf vide"
  | l ->
      let aux clause =
        Printf.printf "%a0\n" print_clause clause in
      List.iter aux l

let rec eval_clause valeurs = function
  | [] -> false (* La clause vide est insatisfiable *)
  | (b,x)::q -> 
      valeurs.(x-1)=b || eval_clause valeurs q

