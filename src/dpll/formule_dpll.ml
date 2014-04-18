open Clause
open Formule
open Debug

exception Found of (variable*bool)



class formule_dpll =
object(self)
  inherit formule as super

  val occurences_pos : clauseset vartable = new vartable 0 (* associe à chaque variable les clauses dans lesquelles elle apparait positivement *)
  val occurences_neg : clauseset vartable = new vartable 0 (* associe à chaque variable les clauses dans lesquelles elle apparait négativement *)

  val singletons = new clauseset

  method init n clauses_init = (* crée l'ensemble des clauses et remplie occurences_pos/neg à partir de clauses_init (int list list = liste de clauses) *)
    super#init n clauses_init;
    for i=1 to n do
      occurences_pos#set i (new clauseset);
      occurences_neg#set i (new clauseset)
    done;
    clauses#iter self#register_clause
      
  method private add_occurence ?(hid=false) c b v = (* ajoute la clause c dans les occurences_pos ou occurences_neg de v, suivant la polarité b *)
    let dest = if b then occurences_pos else occurences_neg in
    let set = match dest#find v with
      | None -> 
          let set = new clauseset in
          dest#set v set;
          set
      | Some set -> set in
    if hid then
      set#add_hid c (* si hid est vrai, on cache c directement *) (***)
    else
      set#add c
          
  method private register_clause c = (* Met c dans les occurences de ses variables *) (****)
    c#get_vpos#iter (self#add_occurence c true);
    c#get_vneg#iter (self#add_occurence c false);
    c#get_vpos#iter_hid (self#add_occurence ~hid:true c true);
    c#get_vneg#iter_hid (self#add_occurence ~hid:true c false);
    if c#size = 1 then
      singletons#add c

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
      | None -> assert false (* cet ensemble aurait du être initialisé *) 
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

  method private show_occurences v_ref c = (* on rend visible c dans les occurences_pos/neg des variables qu'elle contient (exceptée v_ref) *)
    c#get_vpos#iter 
      (fun v -> 
        if v<>v_ref then 
          (self#get_occurences occurences_pos v)#show c);
    c#get_vneg#iter 
      (fun v -> 
        if v<>v_ref then 
          (self#get_occurences occurences_neg v)#show c) 

  (**************************************)

  method find_singleton =
    match singletons#choose with
      | None -> None
      | Some clause ->
          match clause#singleton with
            | Singleton lit -> Some (lit,clause)
            | _ -> assert false

  method find_single_polarite =
    let rec parcours_polar m n = 
      if m>n then 
        None 
      else 
        if not (paris#mem m) then 
          if (self#get_occurences occurences_pos m)#is_empty then 
            match ((self#get_occurences occurences_neg m)#choose) with
              | None -> assert false
              | Some c -> Some (false,m) (* on peut à ce stade renvoyer une var qui n'apparaitrait dans aucune clause *)
          else 
            if (self#get_occurences occurences_neg m)#is_empty then 
              match ((self#get_occurences occurences_pos m)#choose) with
                | None -> assert false
                | Some c -> Some (true,m)
            else parcours_polar (m+1) n
        else parcours_polar (m+1) n
    in parcours_polar 1 self#get_nb_vars


  (**************************************)
  
  method set_val b v ?cl lvl = (***) (* cl : clause ayant provoqué l'assignation, lvl : niveau d'assignation *)
    begin
      match paris#find v with
        | None -> 
            begin
              paris#set v b;
              level#set v lvl;
              match cl with
                | None -> ()
                | Some cl -> origin#set v cl
            end
        | Some _ -> assert false (* Pas de double paris *)
    end;
    let (valider,supprimer) =
      if b then
        (occurences_pos,occurences_neg)
      else
        (occurences_neg,occurences_pos) in
    (self#get_occurences valider v)#iter 
      (fun c -> 
        clauses#hide c ; 
        self#hide_occurences v c;
        match c#singleton with (*ça arrive ça ?*)
          | Singleton _ -> singletons#remove c
          | _ -> ());
    (self#get_occurences supprimer v)#iter 
      (fun c -> 
        c#hide_var (not b) v;
        match c#singleton with
          | Empty ->
              singletons#remove c;
              raise (Empty_clause c) (***) 
          | Singleton _ -> singletons#add c
          | Bigger -> ())
          

          
  method reset_val v = (***)
    let b = match paris#find v with
      | None -> assert false
      | Some b -> 
          paris#remove v ; 
          origin#remove v; (***)
          level#remove v; (***)
          b in
    let (invalider,restaurer) =
      if b then
        (occurences_pos,occurences_neg)
      else
        (occurences_neg,occurences_pos) in
    (self#get_occurences invalider v)#iter 
      (fun c -> 
        clauses#show c;
        self#show_occurences v c;
        match c#singleton with
          | Singleton _ -> singletons#add c
          | _ -> ());
    (self#get_occurences restaurer v)#iter 
      (fun c ->
        c#show_var (not b) v;
        match c#singleton with
          | Singleton _ -> singletons#add c
          | Bigger -> singletons#remove c
          | _ -> ()) 


end


