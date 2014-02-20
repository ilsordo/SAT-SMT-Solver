open Clause

module ClauseSet = Set.Make(OrderedClause)

type f_repr = ClauseSet.t

class clauseset =
object
  val mutable vis = ClauseSet.empty
  val mutable hid = ClauseSet.empty

  method hide c =
    if (ClauseSet.mem c vis) then 
      begin
        vis <- ClauseSet.remove c vis;
        hid <- ClauseSet.add c hid
      end 
      
  method show c =
    if (ClauseSet.mem c hid) then
      begin
        hid <- ClauseSet.remove c hid;
        vis <- ClauseSet.add c vis
      end
        
  method add c = vis <- ClauseSet.add c vis
     
  method mem c = ClauseSet.mem c vis

  method is_empty = ClauseSet.is_empty vis

  method iter f = ClauseSet.iter f vis
end

(*******)

(* Pour stocker occurences, valeurs, n'importe quoi en rapport avec les variables *)
class ['a] vartable n =
object
  val data : (variable,'a) Hashtbl.t = Hashtbl.create n
    
  method size = Hashtbl.length data

  method set v x = Hashtbl.replace data v x

  method mem v = try Some (Hashtbl.find data v) with Not_found -> None

  method remove v = Hashtbl.remove data v

  method iter f = Hashtbl.iter f data
end


class formule n clauses_init =
object (self)
  val clauses = new clauseset
  val occurences_pos = new vartable n
  val occurences_neg = new vartable n
  val paris = new vartable n

  initializer
    List.iter (fun c -> clauses#add (new clause c)) clauses_init;
    clauses#iter self#register_clause

  method private add_occurence b c v =
    let dest = if b then occurences_pos else occurences_neg in
    let set = match dest#mem v with
      | None -> 
          let set = new clauseset in
          dest#set v set;
          set
      | Some set -> set in
    set#add c

  method private register_clause c =
    c#get_vpos#iter (self#add_occurence true c);
    c#get_vneg#iter (self#add_occurence false c)
      
  (**********)

  method add_clause c =
    clauses#add c;
    self#register_clause c

  method get_clauses = clauses

  (* Accède à l'une des listes d'occurences en supposant qu'elle a été initialisée *)
  method private get_occurences occ v =
    match occ#mem v with
      | None -> assert false (* Cette variable aurait du être iniatilisée ... *)
      | Some occurences -> occurences

  (* Cache une clause des listes d'occurences de toutes les variables sauf v_ref *)
  method private hide_occurences v_ref c = (* Tordu non? C'est peut être faux *)
    c#get_vpos#iter (fun v -> if v<>v_ref then (self#get_occurences occurences_pos v)#hide c);
    c#get_vneg#iter (fun v -> if v<>v_ref then (self#get_occurences occurences_neg v)#hide c)      
      
  method set_val b v = 
    let _ = match paris#mem v with
      | None -> paris#set v b
      | Some _ -> assert false in (* Pas de double paris *) 
    let (valider,supprimer) =
      if b then
        (occurences_pos,occurences_neg)
      else
        (occurences_neg,occurences_pos) in
    (self#get_occurences supprimer v)#iter (fun c -> c#hide_var (not b) v); (* On supprime les occurences du littéral *)
    (self#get_occurences valider v)#iter (fun c -> clauses#hide c; self#hide_occurences v c) 
  (* On supprime les clauses où apparait la négation du littéral, elles ne sont plus pointées que par la liste des occurences de v*)

  (* Replace une clause dans les listes d'occurences de ses variables *)
  method private show_occurences v_ref c = (* Tordu non? C'est peut être faux *)
    c#get_vpos#iter (fun v -> if v<>v_ref then (self#get_occurences occurences_pos v)#show c);
    c#get_vneg#iter (fun v -> if v<>v_ref then (self#get_occurences occurences_neg v)#show c)


  method reset_val v =
    let b = match paris#mem v with
      | None -> assert false (* On ne revient pas sur un pari pas fait *)
      | Some b -> b in
    let (annuler,restaurer) =
      if b then
        (occurences_pos,occurences_neg)
      else
        (occurences_neg,occurences_pos) in
    (self#get_occurences annuler v)#iter (fun c -> c#show_var (not b) v); (* On replace les occurences du littéral *)
    (self#get_occurences restaurer v)#iter (fun c -> clauses#show c; self#show_occurences v c) 
(* On restaure les clauses où apparait la négation du littéral, on remet à jour les occurences des variables y apparaissant*)

end

















