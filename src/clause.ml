type variable = int

module OrderedVar = struct
  type t = variable
  let compare = compare
end

(*******)

module VarSet = Set.Make(OrderedVar)

type c_repr = VarSet.t

type 'a classif = Empty | Singleton of 'a | Bigger (* un ensemble de variable est : vide || un singleton || contient 2 variables ou plus *)

type literal = bool * variable (* un littéral = une variable + sa positivité (+=true, -=false) *)

let print_lit_wl p l = (* afficher un littéral *)
  let s = match l with
    | None -> "None"
    | Some (b,var) -> Printf.sprintf "%d : %B" var b in
  Printf.fprintf p "%s" s

(*******)

class varset =
object (self : 'varset)
  val mutable vis = VarSet.empty (* variables visibles du varset *)
  val mutable hid = VarSet.empty (* variables cachées du varset *)
  val mutable size = 0 (* nombre de variables visibles *)
    
  method repr = vis
  
  method unrepr = hid

  method hide x = (* déplace la variable x des variables visibles aux variables cachées (ssi elle est déjà visible) *)
    if (VarSet.mem x vis) then (** on peut éviter ce test et les suivants ? *)
      begin
        vis <- VarSet.remove x vis;
        hid <- VarSet.add x hid;
        size <- size - 1
      end
      
  method show x = (* déplace la variable x des variables cachées aux variables visibles (ssi elle est déjà cachée) *) 
   hid <- VarSet.remove x hid;
   if not (VarSet.mem x vis) then
     begin
       vis <- VarSet.add x vis;
       size <- size + 1
     end
        
  method add x = 
    if not (VarSet.mem x vis) then
      begin
        vis <- VarSet.add x vis; (* ajoute x aux vars visibles *)
        size <- size + 1
      end

  method mem x = VarSet.mem x vis  (* indique si la variable x est dans vis  *)

  method intersects (v : 'varset) = not (VarSet.is_empty (VarSet.inter vis v#repr)) (* indique si l'intersection entre vis et v est vide *)

  method is_empty = VarSet.is_empty vis

  method size = size

  method singleton = (* indique si vis est vide, singleton, ou contient plus de 1 élément *)
    match size with
      | 0 -> Empty
      | 1 -> Singleton (VarSet.choose vis)
      | _ -> Bigger
      
  method iter f = VarSet.iter f vis 

  method iter_all f = VarSet.iter f vis ; VarSet.iter f hid (* iter aussi sur les vars cachées *)
  
  method fold : 'a.(variable -> 'a -> 'a) -> 'a -> 'a = fun f -> fun a -> VarSet.fold f vis a
  
  method fold_all : 'a.(variable -> 'a -> 'a) -> 'a -> 'a = fun f -> fun a -> VarSet.fold f vis (VarSet.fold f hid a) (* fold aussi sur variables cachées *)
  
  method union ?v_union (vs : 'varset) = (* union avec vs, enlever v_union de la clause résultante *)
    vis <- VarSet.union vis vs#repr;
    hid <- VarSet.union hid vs#unrepr;
    match v_union with
      | None -> ()
      | Some v -> 
          vis <- VarSet.remove v vis;
          hid <- VarSet.remove v hid
    
  method mem_all x = (* mem aussi sur vars cachées *)
    (VarSet.mem x vis) || (VarSet.mem x hid)

end
      
(*******)

class clause x clause_init =
object
  val vpos = new varset (* grâce au varset, on peut cacher ou non des variables dans vpos. De même dans vneg *)
  val vneg = new varset
  val id = incr x; !x

  initializer (* construction d'une clause à partir d'une liste d'entier *)
    List.iter 
      (function 
        | (_,x) when x<=0 -> assert false
        | (true,x) -> vpos#add x
        | (false,x) -> vneg#add x)
      clause_init

  method get_id = id (* à chaque clause est associé un identifiant unique, attribué par la formule contenant la clause *)
    
  method get_vpos = vpos (* variables apparaissant positivement dans la clause *)
    
  method get_vneg = vneg (* variables apparaissant négativement dans la clause *)
    
  method is_tauto = vpos#intersects vneg (* indique si la clause est une tautologie *)
    
  method is_empty = vpos#is_empty && vneg#is_empty

  method size = vpos#size + vneg#size
    
  method hide_var b v = (* cache le littéral (b,v) *)
    if b then
      vpos#hide v
    else 
      vneg#hide v

  method show_var b v = (* montre le littéral (b,v) *)
    if b then
      vpos#show v
    else 
      vneg#show v

  method mem b v = (* indique si le littéral (b,v) est (visible) dans la clause *)
    if b then
      vpos#mem v
    else
      vneg#mem v

  method mem_all b v =
    if b then
      vpos#mem_all v
    else
      vneg#mem_all v
      
  method union ?v_union (c : clause) = (* union avec la clause, enlever v_union *)
    vpos#union ?v_union:v_union c#get_vpos;
    vneg#union ?v_union:v_union c#get_vneg
     
  method singleton = (* renvoie Some (v,b) si la clause est un singleton ne contenant que v avec la positivité b, None sinon *)
    match (vpos#singleton, vneg#singleton) with
      | (Empty, Empty) -> Empty
      | (Singleton v, Empty) -> Singleton (true,v)
      | (Empty, Singleton v) -> Singleton (false,v)
      | _ -> Bigger

  (* ces champs ne sont utilisées que pour les watched literals *)
  val mutable wl1 : literal option = None (* premier littéral surveillé dans la clause *)
  val mutable wl2 : literal option = None (* deuxième littéral surveillé dans la clause *)
    
  method get_wl = match (wl1,wl2) with (* obtenir les 2 littéraux surveillés *)
    | (Some l1, Some l2) -> (l1,l2)
    | _ -> assert false (* on surveille forcèment 2 littéraux *)

  method set_wl1 l = (* placer le littéral l sous surveillance, dans wl1 *)
    wl1 <- Some l

  method set_wl2 l = (* placer le littéral l sous surveillance, dans wl2 *)
    wl2 <- Some l
    
  (***)

  method print p () = (* fonction d'affichage de clause *)
    Printf.fprintf p "Clause %d : " id;
    if (wl1,wl2) <> (None,None) then
      Printf.fprintf p "(watched : %a %a) " print_lit_wl wl1 print_lit_wl wl2;
    vpos#iter_all (fun v -> Printf.fprintf p "%d " v);
    vneg#iter_all (fun v -> Printf.fprintf p "-%d " v)

end

(*******)

module OrderedClause = 
struct
  type t = clause
  let compare (c1 : t) c2 = compare c1#get_id c2#get_id
end





