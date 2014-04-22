open Clause
open Debug

module ClauseSet = Set.Make(OrderedClause)

type f_repr = ClauseSet.t

exception Found of (literal*clause)

exception Unsat

exception Empty_clause of clause




class clauseset =
object
  val mutable vis = ClauseSet.empty (* clauses visibles *)
  val mutable hid = ClauseSet.empty (* clauses cachées *)
  val mutable size = 0 (* nombre de clauses visibles *)
  
  method size = size
  
  method hide c = (* cacher la clause c si elle est déjà visible *)
    (** if (ClauseSet.mem c vis) then*) (** on ne met pas cette condition pour gagner en complexité *)
      begin
        vis <- ClauseSet.remove c vis;
        hid <- ClauseSet.add c hid;
        size <- size-1
      end 
      
  method show c = (* montrer la clause c, si elle est déjà cachée *)
    (** if (ClauseSet.mem c hid) then*) (** on ne met pas cette condition pour gagner en complexité *)
      begin
        hid <- ClauseSet.remove c hid;
        vis <- ClauseSet.add c vis;
        size <- size+1
      end
        
  method add c = 
    (** if not (ClauseSet.mem c vis) then *) (** on ne met pas cette condition pour gagner en complexité *)
    vis <- ClauseSet.add c vis; (* ajouter la clause c aux clauses visibles *)
    size <- size+1
      
  method add_hid c = (* ajouter la clause c aux clauses cachées *)
    hid <- ClauseSet.add c hid 
       
  method mem c = ClauseSet.mem c vis (* indique si c est une clause visible *)

  method is_empty = ClauseSet.is_empty vis (* indique s'il n'y a aucune clause visible *)

  method reset = 
    vis <- ClauseSet.empty;
    hid <- ClauseSet.empty
    (* +reset de size ? *)

  method iter f = ClauseSet.iter f vis

  method iter_all f = ClauseSet.iter f vis ; ClauseSet.iter f hid
  
  method fold : 'a.(clause -> 'a -> 'a) -> 'a -> 'a = fun f -> fun a -> ClauseSet.fold f vis a

  method remove c = 
    vis <- ClauseSet.remove c vis;
    size <- size -1 (** ici un test pour s'assurer qu'on remove bien ?*)

  method choose =
    try Some (ClauseSet.choose vis)
    with Not_found -> None

end

(*******)

(* Pour stocker occurences, valeurs, n'importe quoi en rapport avec les variables *)
class ['a] vartable n =
object (self)
  val data : (variable,'a) Hashtbl.t = Hashtbl.create n
    
  method size = Hashtbl.length data

  method is_empty = Hashtbl.length data = 0

  method reset = Hashtbl.clear data

  method set v x = Hashtbl.replace data v x (* peut être utilisé comme fonction d'ajout ou de remplacement : on associe la valeur x à la variable v *)

  method find v = try Some (Hashtbl.find data v) with Not_found -> None

  method mem v = not (self#find v = None)

  method remove v = Hashtbl.remove data v

  method iter f = Hashtbl.iter f data

  method fold : 'b.(variable -> 'a -> 'b -> 'b) -> 'b -> 'b = fun f -> fun a -> Hashtbl.fold f data a

end

(********)

class formule =
object (self)
  val mutable nb_vars = 0 (* nombre de variables dans la formule *)
  val x = ref 0 (* compteur de clauses, permet d'associer un identifiant unique à chaque clause *)
  val clauses = new clauseset (* ensemble des clauses de la formule, peut contenir des clauses cachées/visibles *)
  val paris : bool vartable = new vartable 0 (* associe à chaque variable un pari : None si aucun, Some b si pari b *)
  val origin : clause vartable = new vartable 0 (* clause à l'origine de l'assignation de la var. None si var non assignée, ou si pas de clause d'origine *)
  val level : int vartable = new vartable 0 (* niveau d'assignation (0 : prétraitement, 1 : ...) *)

  method private reset n = 
    x := 0;
    nb_vars <- n;
    clauses#reset;
    paris#reset
    
  method init n clauses_init = (* crée l'ensemble des clauses à partir d'une int list list (= liste de clauses) *)
    self#reset n;
    List.iter (
      fun c -> 
        let c_new = (new clause x c) in 
          if (not c_new#is_tauto) then clauses#add c_new) 
      clauses_init

  (***)

  method get_nb_vars = nb_vars 

  method get_pari v = paris#find v (* indique si v a subi un pari, et si oui lequel *)

  method get_paris = paris
  
  method get_origin v = origin#find v
    
  method get_level v = match level#find v with
    | None -> assert false
    | Some k -> k  
    
  method set_val b v ?cl lvl = (* cl : clause ayant provoquée l'assignation, lvl : niveau d'assignation *)
    match paris#find v with
      | None -> 
          begin
            paris#set v b;
            level#set v lvl;
            match cl with
              | None -> ()
              | Some c ->
                  origin#set v c
          end
      | Some _ -> assert false (* Pas de double paris *)

  method reset_val v = (* annule le pari sur la variable v *)
    match paris#find v with
      | None -> assert false (* on ne peut pas annuler un pari non fait *)
      | Some b -> 
          begin
            paris#remove v;
            origin#remove v;
            level#remove v
          end

  (***)
  
  method new_clause = new clause x [] 
    
  method add_clause c = clauses#add c (* ajoute la clause c, dans les clauses et les occurences *)

  method get_clauses = clauses (* renvoie l'ensembles des clauses de la formule *)

  method get_nb_occ (_:bool) (_:int) = 0 (* Non implémenté *)
  
  method clause_current_size (c:clause)= c#size

  (***)

  method find_singleton = (* renvoie un littéral formant une clause singleton, s'il en existe un *) (*** METHODE jamais utilisée en l'état *)
    try 
      clauses#iter (fun c -> 
        match c#singleton with  
          | Singleton l -> 
              raise (Found (l,c)) 
          | _ -> ());
      None
    with 
      | Found (l,c) -> Some (l,c)

  method check_empty_clause = (* indique s'il existe une clause vide *)
    clauses#iter (fun c -> if c#is_empty then raise Unsat);

  (***)
  
  method eval = (* indique si l'ensemble des paris actuels rendent la formule vraie *)
    let aux b v =
      match paris#find v with
        | Some b' when b=b' -> raise Exit
        | _ -> () in
    try clauses#iter 
          (fun c -> 
            let b = try 
              c#get_vpos#iter (aux true);
              c#get_vneg#iter (aux false);
              false
            with Exit -> true in
            if not b then raise Exit);
        true
    with Exit -> false
  
    method watch (_:clause) (_:literal) (_:literal) = () (***)
 

    
end

