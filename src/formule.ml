open Clause
open Debug

module ClauseSet = Set.Make(OrderedClause)

type f_repr = ClauseSet.t

exception Found of (literal*clause) (***)

exception Init_empty (***)

exception Clause_vide of (literal*clause) (***)




class clauseset =
object
  val mutable vis = ClauseSet.empty (* clauses visibles *)
  val mutable hid = ClauseSet.empty (* clauses cachées *)

  method size = ClauseSet.cardinal vis
  
  method hide c = (* cacher la clause c si elle est déjà visible *)
    if (ClauseSet.mem c vis) then 
      begin
        vis <- ClauseSet.remove c vis;
        hid <- ClauseSet.add c hid
      end 
      
  method show c = (* montrer la clause c, si elle est déjà cachée *)
    if (ClauseSet.mem c hid) then
      begin
        hid <- ClauseSet.remove c hid;
        vis <- ClauseSet.add c vis
      end
        
  method add c = vis <- ClauseSet.add c vis (* ajouter la clause c aux clauses visibles *)
     
  method mem c = ClauseSet.mem c vis (* indique si c est une clause visible *)

  method is_empty = ClauseSet.is_empty vis (* indique s'il n'y a aucune clause visible *)

  method reset = 
    vis <- ClauseSet.empty;
    hid <- ClauseSet.empty

  method iter f = ClauseSet.iter f vis

  method fold : 'a.(clause -> 'a -> 'a) -> 'a -> 'a = fun f -> fun a -> ClauseSet.fold f vis a

  method remove c = vis <- ClauseSet.remove c vis 

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
  val origin : clause option vartable = new vartable 0
  val level : int option = new vartable 0

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

  method get_pari v = (* indique si v a subi un pari, et si oui lequel *)
    paris#find v

  method get_paris = paris

  method set_val b v ?(cl=None) ?(lvl=None) = (****) (* enlever ces méthodes ? *)
    ()
    (*
      match paris#find v with
      | None -> 
          begin
            paris#set v b;
            origin#set v cl;
            level#set v lvl
          end
      | Some _ -> assert false 
     *)

  method reset_val v = (* annule le pari sur la variable v *) (****)
    ()
    (*match paris#find v with
      | None -> assert false
      | Some b -> 
          begin
            paris#remove v;
            origin#remove v;
            level#remove v
          end
    *)      
  (***)

  method add_clause c = (* ajoute la clause c, dans les clauses et les occurences *)
    clauses#add c

  method get_clauses = clauses (* renvoie l'ensembles des clauses de la formule *)

  method get_nb_occ (_:bool) (_:int) = 0 (* Non implémenté *)
  
  method clause_current_size (_:clause) = 0

  (***)

  method find_singleton = (* renvoie un littéral formant une clause singleton, s'il en existe un *) (*** cette fonction est à modif ? *)
    try 
      clauses#iter (fun c -> 
        match c#singleton with  
          | Singleton x -> 
              raise (Found (x,c)) (***) 
          | _ -> ());
      None
    with 
      | Found (x,c) -> Some (x,c)

  (* indique s'il existe une clause vide *)
  method check_empty_clause = 
    try
      clauses#iter (fun c -> if c#is_empty then raise Init_empty);
      true
    with
      | Init_empty -> false

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
  
  (*  
  method set_origin v c = (***)
    match origin#find v with
      | None -> origin#set v (Some c)
      | Some _ -> assert false 

  method reset_origin v = (***)
    match origin#find v with
      | None -> assert false
      | Some c -> origin#remove v
  *)   
  
  method get_origin v = match origin#find v with(***)
    | None -> assert false
    | Some c -> c
      
  method new_clause = (***)
    (new clause x []) 
    
  method get_level v = match level#find v with(***)
    | None -> assert false
    | Some k -> k  
    
end

