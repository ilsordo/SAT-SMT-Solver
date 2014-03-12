open Clause
open Debug

module ClauseSet = Set.Make(OrderedClause)

type f_repr = ClauseSet.t

exception Found of (variable*bool)

exception Clause_vide

class clauseset =
object
  val mutable vis = ClauseSet.empty (* clauses visibles *)
  val mutable hid = ClauseSet.empty (* clauses cachées *)

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
end


(********)


class formule =
object (self)
  val mutable nb_vars = 0 (* nombre de variables dans la formule *)
  val x = ref 0 (* compteur de clauses, permet d'associer un identifiant unique à chaque clause *)
  val clauses = new clauseset (* ensemble des clauses de la formule, peut contenir des clauses cachées/visibles *)
  val paris : bool vartable = new vartable 0 (* associe à chaque variable un pari : None si aucun, Some b si pari b *)

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
    
  (***)

  method add_clause c = (* ajoute la clause c, dans les clauses et les occurences *)
    clauses#add c

  method get_clauses = clauses (* renvoie l'ensembles des clauses de la formule *)

  method set_val b v = (* pari la valeur b sur la variable v *)
    match paris#find v with
      | None -> paris#set v b
      | Some _ -> assert false 

  method reset_val v = (* annule le pari sur la variable v *)
    match paris#find v with
      | None -> assert false
      | Some b -> paris#remove v

  (******)

  method find_singleton = (* renvoie un littéral formant une clause singleton, s'il en existe un *)
    try 
      clauses#iter (fun c -> 
        match c#singleton with  
          | Some x -> 
              raise (Found x) 
          | None -> ());
      None
    with 
      | Found x -> Some x

  method check_empty_clause = clauses#iter (fun c -> if c#is_empty then raise Clause_vide) (* indique s'il existe une clause vide *)

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

end

