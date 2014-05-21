(* 
   Les outils ci-dessous permettent de convertir une cnf dont les variables sont des choses, en une cnf dont les variables sont des int.
   Ceci permet d'obtenir une cnf au format DIMACS.
   On conserve par ailleurs les renommages effectués dans une table d'association, ce qui permet à l'utilisateur de les afficher (voir option -print_cnf) 
*)

type 'a super_atom = Real of 'a | Virtual of int

type 'a reduction =
<
  max : int;
    
  bind : 'a -> int;

  get_id : 'a -> int option;

  get_orig : int -> 'a option;

  iter : ('a -> int -> unit) -> unit;

  fold : 'b.('a -> int -> 'b -> 'b) -> 'b -> 'b;
    
  print_reduction : out_channel -> unit
>

module Reduction (Base : sig type t val print_value : out_channel -> t -> unit end) =
struct
  
  module Id = Map.Make(struct type t = Base.t let compare = compare end)
  module Orig = Map.Make(struct type t = int let compare = compare end)

  (* Table de correspondance entre des choses et des noms de variables (int) *)
  let reduction start =
  object (self)
    val mutable count = start (* l'objet gère ses variables fraiches *)

    val mutable ids : int Id.t = Id.empty (* t vers int *)

    val mutable orig : Base.t Orig.t = Orig.empty (* int vers t *)
      
  (* Variable maximale utilisée *)
    method max = count - 1

    method private get_fresh =
      count <- count + 1;
      count - 1
        
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

    method fold : 'a.(Id.key -> Orig.key -> 'a -> 'a) -> 'a -> 'a = fun f -> fun a -> Id.fold f ids a
    
    method print_reduction p = (* affiche la correspondance entre string et int *)
      Printf.fprintf p "c Renommage : \n"; 
      Id.iter (fun s n -> Printf.fprintf p "c %a  ->  %d\n" Base.print_value s n) ids;
      Printf.fprintf p "\n"; 
      
  end


  let renommer ?(start = 1) f = (* renvoie CNF avec vars normalisées + table d'association *)
    let assoc = reduction start in
    let renommer_litteral = function
        | (b, Virtual x) -> (b,x) 
        | (b, Real a) -> 
            let x = match assoc#get_id a with
              | Some x -> x
              | None -> assoc#bind a in
            (b, x) in
    let renommer_clause = List.rev_map renommer_litteral in
    (List.rev_map renommer_clause f, assoc)

end

(* énumère les f(n0), f(n0 + 1) , etc *)
class ['a] counter n0 (f:int->'a) =
object
  val mutable n = n0 - 1

  method next = n <- n + 1; f n
    
  method count = n - n0
end

