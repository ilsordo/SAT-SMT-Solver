(* 
   Les outils ci-dessous permettent de convertir une cnf dont les variables sont des strings, en une cnf dont les variables sont des int.
   Ceci permet d'obtenir une cnf au format DIMACS
   On conserve par ailleurs les renommages effectués dans une table d'association, ce qui permet à l'utilisateur de les afficher (voir option -print_cnf) 
*)

type print_answer_t = out_channel -> Answer.t -> unit

type 'a super_atom = Real of 'a | Virtual of int

class type ['a] reduction =
object
  method max : int
    
  method bind : Base.t -> int

  method get_id : Base.t -> int option

  method get_orig : int -> Base.t option

  method iter : (Base.t -> int -> unit) -> unit

  method print_answer : print_answer_t
    
  method print_reduction : out_channel -> unit
end


module Reduction (Base : sig type t val print_value : t -> string end) =
struct
  
  module Id = Map.Make(struct type t = Base.t let compare = compare end)
  module Orig = Map.Make(struct type t = int let compare = compare end)

  (* Table de correspondance entre des choses et des noms de variables (int) *)
  class reduction ?(start = 1) (print_answer : reduction  -> print_answer_t) =
  object (self)
    val mutable count = start (* l'objet gère ses variables fraiches *)

    val mutable ids : int Id.t = Id.empty (* t vers int *)

    val mutable orig : Base.t Orig.t = Orig.empty (* int vers t *)
      
  (* Variable maximale utilisée *)
    method max = count

    method private get_fresh = 
      count;
      count <- count + 1
        
    method bind s = (* renvoie l'entier associé au string s. Crée un entier frais si s pas encore rencontré *)
      assert (not (Id.mem s ids)); (* Par sécurité *)
      let x = self#get_fresh in
      ids <- Id.add s x ids;
      orig <- Orig.add x s orig;
      x
        
    method get_id s = (* renvoie l'entier associé au string s*)
      try 
        Some (Id.find s ids)
      with Not_found -> None

    method get_orig x = (* renvoie le string associé à l'int x *)
      try 
        Some (Orig.find x orig)
      with Not_found -> None
        
    method iter f = Id.iter f ids

    method fold f a = Id.fold f ids a
    
    method print_answer p answer = print_answer (self:>reduction) p answer
      
    method print_reduction p = (* affiche la correspondance entre string et int *)
      Printf.fprintf p "c Renommage : \n"; 
      Id.iter (fun s n -> Printf.fprintf p "c %s  ->  %d\n" (Base.print_value s) n) ids;
      Printf.fprintf p "\n"; 
      
  end


  let renommer ?(start = 1) f print_answer = (* renvoie CNF avec vars normalisées + table d'association *)
    let renommer_clause assoc =
      let signe b = 
        if b then 1 else -1 in
      let assoc = new reduction ~start:start print_answer in
      let renommer_litteral = function
        | (b, Virtual x) -> signe b * x  
        | (b, Real a) -> 
            let x = match assoc#get_id a with
              | Some x -> x
              | None -> assoc#bind v in
            signe b * x in
      List.rev_map renommer_litteral in
    (List.rev_map (renommer_clause assoc) f, assoc)

end

(* énumère les f(n0), f(n0 + 1) , etc *)
class ['a] counter n0 (f:int->'a) =
object
  val mutable n = n0 - 1

  method next = n <- n + 1; f n
    
  method count = n - n0
end

