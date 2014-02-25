open Clause

module ClauseSet = Set.Make(OrderedClause)

type f_repr = ClauseSet.t

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

  method iter f = ClauseSet.iter f vis

  method fold f a = ClauseSet.fold f vis a

  method filter f = ClauseSet.elements (ClauseSet.filter f vis) (* renvoie la liste des élements de vis satisfaisant le prédicat f *)
end

(*******)

(* Pour stocker occurences, valeurs, n'importe quoi en rapport avec les variables *)
class ['a] vartable n =
object (self)
  val data : (variable,'a) Hashtbl.t = Hashtbl.create n
    
  method size = Hashtbl.length data

  method set v x = Hashtbl.replace data v x (* peut être utilisé comme fonction d'ajout ou de remplacement : on associe la valeur x à la variable v *)

  method find v = try Some (Hashtbl.find data v) with Not_found -> None

  method mem v = not (self#find v = None)

  method remove v = Hashtbl.remove data v

  method iter f = Hashtbl.iter f data
end


(********)


class formule n clauses_init =
object (self)
  val clauses = new clauseset (* ensemble des clauses de la formule, peut contenir des clauses cachées/visibles *)
  val occurences_pos : clauseset vartable = new vartable n (* associe à chaque variable les clauses auxquelles elle appartient (clauses pouvant être cachées ou non) *)
  val occurences_neg : clauseset vartable = new vartable n
  val paris : bool vartable = new vartable n (* associe à chaque variable un pari : None si aucun, Some b si pari b *)

  initializer
    for i=1 to n do
      occurences_pos#set i (new clauseset);
      occurences_neg#set i (new clauseset)
    done;
    List.iter (fun c -> clauses#add (new clause c)) clauses_init;
    clauses#iter self#register_clause

(***)

  method get_nb_vars = n

  method get_pari v = (* indique si v a subi un pari, et si oui lequel *)
    paris#find v

  method get_paris = paris (** nécessaire pour renvoyer dans dpll Solvable ... ? *)

(***)

  method private add_occurence b c v = (* ajoute la clause c dans les occurences_pos ou occurences_neg de v, suivant la polarité b *)
    let dest = if b then occurences_pos else occurences_neg in
    let set = match dest#find v with
      | None -> 
          let set = new clauseset in
          dest#set v set;
          set
      | Some set -> set in
    set#add c

  method private register_clause c = (* Met c dans les listes d'occurences de ses variables *)
    c#get_vpos#iter (self#add_occurence true c);
    c#get_vneg#iter (self#add_occurence false c)
      
(***)

  method add_clause c = (* ajoute la clause c, dans les clauses et les occurences *)
    clauses#add c;
    self#register_clause c

  method get_clauses = clauses

  (* Accède à l'une des listes d'occurences en supposant qu'elle a été initialisée *)
  method private get_occurences occ v =
    match occ#find v with
      | None -> assert false 
      (* Cette variable aurait du être initialisée à l'ajout de la clause *) 
      | Some occurences -> occurences

  (* Cache une clause des listes d'occurences de toutes les variables sauf v_ref *)
  method private hide_occurences v_ref c = (* Tordu non? C'est peut être faux *) (** est-ce pertinent de ne pas cacher les occurences de v_ref ? *)
    c#get_vpos#iter (fun v -> if v<>v_ref then (self#get_occurences occurences_pos v)#hide c);
    (* on n'a pas un pb si après on show une var de vpos_hide ? *)
    (** c n'est plus accessible que par les occurences de v_ref et le seul moyen d'y accéder est de faire un reset_val *)
    c#get_vneg#iter (fun v -> if v<>v_ref then (self#get_occurences occurences_neg v)#hide c)      
      
  method set_val b v = (* on souhaite assigner la variable v à b (true ou false), et faire évoluer les clauses en conséquences *)
    let clause_vide = ref true in
    let _ = match paris#find v with
      | None -> paris#set v b
      | Some _ -> assert false in (* Pas de double paris *) 
    let (valider,supprimer) =
      if b then
        (occurences_pos,occurences_neg)
      else
        (occurences_neg,occurences_pos) in
    (* On supprime les occurences du littéral *) 
    (self#get_occurences supprimer v)#iter (fun c -> c#hide_var (not b) v ; if c#is_empty then clause_vide := false); (*** c'est ici qu'on fait apparaitre des clauses vides *)(* Des références? Horreur et damnation! *)
    (* On supprime les clauses où apparait la négation du littéral, elles ne sont plus pointées que par la liste des occurences de v*)
    (self#get_occurences valider v)#iter (fun c -> clauses#hide c; self#hide_occurences v c);
    !clause_vide


  (* Replace une clause dans les listes d'occurences de ses variables *)
  method private show_occurences v_ref c = (* Tordu non? C'est peut être faux *)
    c#get_vpos#iter (fun v -> if v<>v_ref then (self#get_occurences occurences_pos v)#show c);
    c#get_vneg#iter (fun v -> if v<>v_ref then (self#get_occurences occurences_neg v)#show c)

  method reset_val v =
    let b = match paris#find v with
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

(******)

  method find_singleton = (* renvoie la liste des var sans pari qui forment une clause singleton *)
    clauses#fold (fun c acc -> match c#singleton with Some x -> x::acc | None -> acc) []
    

  method find_single_polarite = (* on cherche une var sans pari qui n'apparaitrait qu'avec une seule polarité *)
    let rec parcours_polar m n = 
      if m>n 
      then None 
      else  if not (paris#mem m) 
            then if (self#get_occurences occurences_pos m)#is_empty 
                 then Some (m,true) (* on peut à ce stade renvoyer une var qui n'apparaitrait dans aucune clause *)
                 else if (self#get_occurences occurences_neg m)#is_empty
                      then Some (m,false)
                      else parcours_polar (m+1) n
            else parcours_polar (m+1) n
    in parcours_polar 1 self#get_nb_vars
end

















