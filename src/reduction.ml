(* 
   Les outils ci-dessous permettent de convertir une cnf dont les variables sont des strings, en une cnf dont les variables sont des int.
   Ceci permet d'obtenir une cnf au format DIMACS
   On conserve par ailleurs les renommages effectués dans une table d'association, ce qui permet à l'utilisateur de les afficher (voir option -print_cnf) 
*)

type print_answer_t = out_channel -> Answer.t -> unit

module Reduction (Base : sig type t val print_value : t -> string end) =
struct
  
  module Id = Map.Make(struct type t = Base.t let compare = compare end)
  module Orig = Map.Make(struct type t = int let compare = compare end)

  (* Table de correspondance entre des choses et des noms de variables (int) *)
  class reduction (print_answer : reduction  -> print_answer_t) =
  object (self)
    val mutable count = 0 (* l'objet gère ses variables fraiches *)

    val mutable ids : int Id.t = Id.empty (* t vers int *)

    val mutable orig : Base.t Orig.t = Orig.empty (* int vers string *)
      
  (* Variable maximale utilisée *)
    method max = count

    method private get_fresh = 
      count <- count + 1;
      count
        
    method bind s = (* renvoie l'entier associé au string s. Crée un entier frais si s pas encore rencontré *)
      assert (not (Id.mem s values)); (* Par sécurité *)
      let x = self#get_fresh in
      values <- Id.add s x values;
      names <- Orig.add x s names;
      x
        
    method get_value s = (* renvoie l'entier associé au string s*)
      try 
        Some (Id.find s values)
      with Not_found -> None

    method get_name x = (* renvoie le string associé à l'int x *)
      try 
        Some (Orig.find x names)
      with Not_found -> None
        
    method iter f = Id.iter f values

    method print_answer p answer = print_answer (self:>reduction) p answer
      
    method print_reduction p = (* affiche la correspondance entre string et int *)
      Printf.fprintf p "c Renommage : \n"; 
      Id.iter (fun s n -> Printf.fprintf p "c %s  ->  %d\n" (Base.print_value s) n) values;
      Printf.fprintf p "\n"; 
      
  end
    
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

