open Clause
open Formule
open Debug

exception Found of (variable*bool)

class formule_dpll =
object(self)
  inherit formule as super

  val occurences_pos : clauseset vartable = new vartable 0 (* associe à chaque variable les clauses dans lesquelles elle apparait positivement *)
  val occurences_neg : clauseset vartable = new vartable 0 (* associe à chaque variable les clauses dans lesquelles elle apparait négativement *)

  method init n clauses_init = (* crée l'ensemble des clauses et remplie occurences_pos/neg à partir de clauses_init (int list list = liste de clauses) *)
    super#init n clauses_init;
    for i=1 to n do
      occurences_pos#set i (new clauseset);
      occurences_neg#set i (new clauseset)
    done;
    clauses#iter self#register_clause
      
  method private add_occurence b c v = (* ajoute la clause c dans les occurences_pos ou occurences_neg de v, suivant la polarité b *)
    let dest = if b then occurences_pos else occurences_neg in
    let set = match dest#find v with
      | None -> 
          let set = new clauseset in
          dest#set v set;
          set
      | Some set -> set in
    set#add c
     
  method private register_clause c = (* Met c dans les occurences de ses variables *)
    c#get_vpos#iter (self#add_occurence true c);
    c#get_vneg#iter (self#add_occurence false c)

  method add_clause c = (* ajoute la clause c, et met à jour occurences_pos/neg en conséquence *)
    super#add_clause c;
    self#register_clause c
  
  method get_nb_occ b x = 
    let occ = if b then occurences_pos else occurences_neg in
      match occ#find x with
        | None -> assert false
        | Some occ -> occ#size
    
  method clause_current_size c = c#size
  
  method private get_occurences occ v =  (* Accède à l'une des occurences (occ) de la variable v, en supposant que cet ensemble a été initialisé *)
    match occ#find v with
      | None -> debug#p 1 "AAARGH %d" v;assert false (* cet ensemble aurait du être initialisé *) 
      | Some occurences -> occurences

  method private hide_occurences v_ref c =  (* Cache une clause des occurences de toutes les variables qu'elle contient, sauf v_ref *)
    c#get_vpos#iter 
      (fun v -> 
        if v<>v_ref then 
          (self#get_occurences occurences_pos v)#hide c);     
    c#get_vneg#iter 
      (fun v -> 
        if v<>v_ref then 
          (self#get_occurences occurences_neg v)#hide c)    

  method set_val b v = (* on assigne la valeur b à la variable v, on cache les causes qui deviennent vraie, on cache v dans les clauses où elle est fausse *)
    let _ = match paris#find v with
      | None -> paris#set v b
      | Some _ -> assert false in (* Pas de double paris *)
    let (valider,supprimer) =
      if b then
        (occurences_pos,occurences_neg)
      else
        (occurences_neg,occurences_pos) in
    (* On supprime (valide) les clauses où apparait le littéral (b,v) (ces clauses sont devenues vraies), elles ne sont plus pointées que par la liste des occurences de v*)
    (self#get_occurences valider v)#iter 
      (fun c -> 
        clauses#hide c ; 
        self#hide_occurences v c);
      (* On supprime la négation du littéral des clauses où elle
         apparait, si on créé un conflit on le dit *)
      (self#get_occurences supprimer v)#iter 
        (fun c -> 
          c#hide_var (not b) v;
          if c#is_empty then 
            raise Clause_vide)

  method private show_occurences v_ref c = (* on rend visible c dans les occurences_pos/neg des variables qu'elle contient (exceptée v_ref) *)
    c#get_vpos#iter 
      (fun v -> 
        if v<>v_ref then 
          (self#get_occurences occurences_pos v)#show c);
    c#get_vneg#iter 
      (fun v -> 
        if v<>v_ref then 
          (self#get_occurences occurences_neg v)#show c) 
      
  method reset_val v = (* on souhaite annuler le pari sur la variable v, et rendre visible tout ce qui a été caché par set_val ci-dessus *)
    let b = match paris#find v with
      | None -> assert false (* on n'annule pas un pari pas fait *)
      | Some b -> 
          paris#remove v ; 
          b in
    let (invalider,restaurer) =
      if b then
        (occurences_pos,occurences_neg)
      else
        (occurences_neg,occurences_pos) in
    (* On rend visible les clauses qui étaient vraies grâce à v *)
    (self#get_occurences invalider v)#iter 
      (fun c -> 
        clauses#show c;
        self#show_occurences v c);
    (* On rend visible v dans les clauses où elle était cachée car fausse *)
    (self#get_occurences restaurer v)#iter 
      (fun c -> 
        c#show_var (not b) v) 

(***)

  method find_single_polarite = (* on cherche une var sans pari qui n'apparaitrait qu'avec une seule polarité *)
    let rec parcours_polar m n = 
      if m>n then 
        None 
      else 
        if not (paris#mem m) then 
          if (self#get_occurences occurences_pos m)#is_empty then 
            Some (false,m) (* on peut à ce stade renvoyer une var qui n'apparaitrait dans aucune clause *)
          else 
            if (self#get_occurences occurences_neg m)#is_empty then 
              Some (true,m)
            else parcours_polar (m+1) n
        else parcours_polar (m+1) n
    in parcours_polar 1 self#get_nb_vars


end
