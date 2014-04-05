module Values = Map.Make(String)
module Names = Map.Make(struct type t = int let compare = compare end)

type print_answer_t = out_channel -> Answer.t -> unit

(* 
   Les outils ci-dessous permettent de convertir une cnf dont les variables sont des strings, en une cnf dont les variables sont des int.
   Ceci permet d'obtenir une cnf au format DIMACS
   On conserve par ailleurs les renommages effectués dans une table d'association, ce qui permet à les utilisateurs de les afficher (voir option -print_cnf) 
*)


(* Table de correspondance entre des chaines de caractères et des noms de variables (int) *)
class reduction (f : reduction  -> print_answer_t) =
object (self)
  val mutable count = 0 (* l'objet gère ses variables fraiches *)

  val mutable values : int Values.t = Values.empty (* string vers int *)

  val mutable names : string Names.t = Names.empty (* int vers string *)
  
  (* Variable maximale utilisée *)
  method max = count

  method private get_fresh = 
    count <- count + 1;
    count
  
  method bind s = (* renvoie l'entier associé au string s. Crée un entier frais si s pas encore rencontré *)
    assert (not (Values.mem s values)); (* Par sécurité *)
    let x = self#get_fresh in
    values <- Values.add s x values;
    names <- Names.add x s names;
    x
  
  method get_value s = (* renvoie l'entier associé au string s*)
    try 
      Some (Values.find s values)
    with Not_found -> None

  method get_name x = (* renvoie le string associé à l'int x *)
    try 
      Some (Names.find x names)
    with Not_found -> None
       
  method iter f = Values.iter f values

  method print_answer p answer = f (self:>reduction) p answer

  method print_reduction p = (* affiche la correspondance entre string et int *)
    Printf.fprintf p "c Renommage : \n"; 
    Values.iter (fun s n -> Printf.fprintf p "c %s  ->  %d\n" s n) values;
    Printf.fprintf p "\n"; 
    
end



let signe b = 
  if b then 1 else -1

let renommer_clause assoc = 
  let renommer_litteral (b,v) =
    let x = match assoc#get_value v with
      | Some x -> x
      | None -> assoc#bind v in
    signe b * x in
  List.rev_map renommer_litteral

  
let renommer f print_answer = (* renvoie CNF avec vars normalisées + table d'association *)
  let assoc = new reduction print_answer in
  (List.rev_map (renommer_clause assoc) f, assoc)


(* énumère les f(n0), f(n0 + 1) , etc *)
class ['a] counter n0 (f:int->'a) =
object
  val mutable n = n0 - 1

  method next = n <- n + 1; f n
end










