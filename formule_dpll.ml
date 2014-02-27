open Clause
open Formule
open Debug

exception Found of (variable*bool)

class formule_dpll =
object(self)
  inherit formule as super

  val occurences_pos : clauseset vartable = new vartable 0 (* associe à chaque variable les clauses auxquelles elle appartient *)
  val occurences_neg : clauseset vartable = new vartable 0

  method init n clauses_init =
    super#init n clauses_init;
    for i=1 to n do
      occurences_pos#set i (new clauseset);
      occurences_neg#set i (new clauseset)
    done;
    clauses#iter self#register_clause

  method add_clause c =
    super#add_clause c;
    self#register_clause c
      
  method private add_occurence b c v = (* ajoute la clause c dans les occurences_pos ou occurences_neg de v, suivant la polarité b *)
    let dest = if b then occurences_pos else occurences_neg in
    let set = match dest#find v with
      | None -> 
          let set = new clauseset in (***)
          dest#set v set;
          set
      | Some set -> set in
    set#add c
      
  method private register_clause c = (* Met c dans les listes d'occurences de ses variables *)
    c#get_vpos#iter (self#add_occurence true c);
    c#get_vneg#iter (self#add_occurence false c)

  (* Accède à l'une des listes d'occurences en supposant qu'elle a été initialisée *)
  method private get_occurences occ v =
    match occ#find v with
      | None -> assert false 
      (* Cette variable aurait du être initialisée à l'ajout de la clause *) 
      | Some occurences -> occurences

  (* Cache une clause des listes d'occurences de toutes les variables sauf v_ref *)
  method private hide_occurences v_ref c =
    c#get_vpos#iter 
      (fun v -> 
        if v<>v_ref then 
          (self#get_occurences occurences_pos v)#hide c);     
    c#get_vneg#iter 
      (fun v -> 
        if v<>v_ref then 
          (self#get_occurences occurences_neg v)#hide c)    

  method set_val b v = (* on souhaite assigner la variable v à b (true ou false), et faire évoluer les clauses en conséquences *)
    let _ = match paris#find v with
      | None -> paris#set v b
      | Some _ -> assert false in (* Pas de double paris *)
    let (valider,supprimer) =
      if b then
        (occurences_pos,occurences_neg)
      else
        (occurences_neg,occurences_pos) in
    (* On supprime (valide) les clauses où apparait le littéral, elles ne sont plus pointées que par la liste des occurences de v*)
    (self#get_occurences valider v)#iter 
      (fun c -> 
        clauses#hide c ; 
        self#hide_occurences v c);
    (* On supprime la négation du littéral des clauses où elle apparait, si on créé un conflit on le dit *)
    (self#get_occurences supprimer v)#iter 
      (fun c -> 
        c#hide_var (not b) v;
        if c#is_empty then 
          raise Clause_vide)

  method private show_occurences v_ref c =
    c#get_vpos#iter 
      (fun v -> 
        if v<>v_ref then 
          (self#get_occurences occurences_pos v)#show c);
    c#get_vneg#iter 
      (fun v -> 
        if v<>v_ref then 
          (self#get_occurences occurences_neg v)#show c) 
      
  (* Replace une clause dans les listes d'occurences de ses variables *)
  method reset_val v =
    let b = match paris#find v with
      | None -> assert false (* On ne revient pas sur un pari pas fait *)
      | Some b -> 
          paris#remove v ; 
          b in
    let (invalider,restaurer) =
      if b then
        (occurences_pos,occurences_neg)
      else
        (occurences_neg,occurences_pos) in
    (* On invalide les clauses où apparaissait le littéral *)
    (self#get_occurences invalider v)#iter 
      (fun c -> 
        clauses#show c;
        self#show_occurences v c);
    (* On restaure les clauses où apparait la négation du littéral, on remet à jour les occurences des variables y apparaissant*)
    (self#get_occurences restaurer v)#iter 
      (fun c -> 
        c#show_var (not b) v) (* On replace les occurences du littéral *)

(***)

  method find_single_polarite = (* on cherche une var sans pari qui n'apparaitrait qu'avec une seule polarité *)
    let rec parcours_polar m n = 
      if m>n 
      then None 
      else  if not (paris#mem m) 
        then if (self#get_occurences occurences_pos m)#is_empty 
          then Some (m,false) (* on peut à ce stade renvoyer une var qui n'apparaitrait dans aucune clause *)
          else if (self#get_occurences occurences_neg m)#is_empty
          then Some (m,true)
          else parcours_polar (m+1) n
          else parcours_polar (m+1) n
    in parcours_polar 1 self#get_nb_vars

end
