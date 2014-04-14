open Clause
open Formule
open Debug

exception Found of literal

exception WLs_found of (literal*literal)

exception WL_found of literal

type wl_update = WL_Conflit | WL_New of literal | WL_Assign of literal | WL_Nothing

(* ces types indiquent ce qui se passe lorsqu'on essaye de déplacer les jumelles dans une clause : 
      WL_Conflit : tous les littéraux de la clause sont à faux
      WL_New : un nouveau littéral a été trouvé et la surveillance a été déplacée dessus
      WL_Assign l : le littéral l doit subir une assignation (seul littéral non nul de la clause)
      WL_Nothing : on surveille déjà un littéral à vrai dans la clause, rien à faire
*)


(***************************************************)


class formule_wl =
object(self)
  inherit formule as super

  val wl_pos : clauseset vartable = new vartable 0 (* pour chaque variable, les clauses où elle apparait positivement et est surveillée *)
  val wl_neg : clauseset vartable = new vartable 0 (* pour chaque variable, les clauses où elle apparait négativement et est surveillée *)

  method get_wl lit = (* obtenir les clauses où le littéral lit est surveillé *)
    if (fst lit) then
      match wl_pos#find (snd lit) with
        | None -> assert false (* aurait du être initialisé avant *)
        | Some s -> s
    else
      match wl_neg#find (snd lit) with
        | None -> assert false (* aurait du être initialisé avant *)
        | Some s -> s

  method clause_current_size c =
    c#get_vpos#fold 
      (fun v res -> if self#get_pari v = None then res+1 else res) 
      (c#get_vneg#fold
        (fun v res -> if self#get_pari v = None then res+1 else res)  
        0)

  method get_nb_occ b x = 
    let occ = if b then wl_pos else wl_neg in
    match occ#find x with
      | None -> assert false
      | Some occ -> occ#size
      
  (* init = prétraitement : enlève tautologies + détecte clauses singletons et fait des assignations en conséquence
     ATTENTION : init ne détecte aucune clause vide (mais peut en créer). Il faudra s'assurer de l'absence de clauses vides par la suite *)
  method init n clauses_init =
    for i=1 to n do (* on remplie wl_pos et wl_neg par du vide *)
      wl_pos#set i (new clauseset);
      wl_neg#set i (new clauseset)
    done;
    super#init n clauses_init; (* enlève les tautologies, construit les clauses *)
    let (occ_pos,occ_neg) = (new vartable n, new vartable n) in (* stockage temporaire pour chaque variable des clauses où elle apparait positivement/négativement *)
    let add_occurence dest c v = (* ajoute la clause c dans les occurences_pos ou occurences_neg de v, suivant la polarité b *)
      let set = match dest#find v with
        | None -> 
            let set = new clauseset in
            dest#set v set;
            set
        | Some set -> set in
      set#add c in
    let register_clause c = (* Met c dans les listes d'occurences de ses variables *)
      c#get_vpos#iter (add_occurence occ_pos c);
      c#get_vneg#iter (add_occurence occ_neg c) in
    clauses#iter register_clause; (* remplit occ_pos et occ_neg *)
    let get_occurences occ var =  (* permet d'obtenir occ_pos ou neg d'une var *)
      match occ#find var with
        | None -> new clauseset
        | Some occurences -> occurences in
    let rec prepare () = (* trouve les clauses singletons, effectue les assignations/changement de clauses qui en découlent *)
      let res = 
        try 
          clauses#iter (fun c -> match c#singleton with Singleton s -> raise (Found s) | _ -> ());
          None
        with Found s -> Some s in
      match res with
        | None -> ()
        | Some (b,v) ->
            paris#set v b;
            let (valider,supprimer) =
              if b then
                (occ_pos,occ_neg)
              else
                (occ_neg,occ_pos) in
            (get_occurences valider v)#iter 
              (fun c -> clauses#remove c);
            (get_occurences supprimer v)#iter 
              (fun c -> c#hide_var (not b) v);
            prepare() in
    prepare() 


  (* Initialise les watched literals en en choisissant 2 par clauses. On s'assurera avant qu'aucune clause n'est singleton *)
  method init_wl =
    let pull b v temp = (* Extrait 2 éléments *)
      match temp with None -> Some (b,v) | Some l -> raise (WLs_found (l,(b,v))) in
    clauses#iter
      (fun c -> 
        try 
          ignore (c#get_vpos#fold (pull true) (c#get_vneg#fold (pull false) None));
          assert false 
        with
          | WLs_found (l1,l2) ->
              (self#get_wl l1)#add c; (* l1 sait qu'il surveille c*)
              (self#get_wl l2)#add c; (* l2 sait qu'il surveille c*)
              c#set_wl1 l1; (* c sait qu'il est surveillé par l1*)
              c#set_wl2 l2) (* c sait qu'il est surveillé par l2*)



  (********* Les 2 méthodes le plus utiles au cours de l'algo WL :   *********)

  method watch c l l_former = (* on veut que le littéral l surveille la clause c, et que l_former stop sa surveillance sur c *)
    (self#get_wl l)#add c; (* l sait qu'il surveille c *)
    let (wl1,wl2) = c#get_wl in
    if l_former = wl1 then
      begin
        c#set_wl1 l; (* c sait qu'il est surveillé par l *)
        (self#get_wl l_former)#remove c (* l_former sait qu'il ne surveille plus c *)
      end
    else
      begin
        c#set_wl2 l; (* c sait qu'il est surveillé par l *)
        (self#get_wl l_former)#remove c (* l_former sait qu'il ne surveille plus c *)
      end


  method update_clause c wl = (* on doit quitter la surveillance du littéral wl dans la clause c car un pari vient de le rendre faux // on présuppose wl faux dans c *)
    let (wl1,wl2) = c#get_wl in (* on récupère les deux littéraux actuellement surveillés dans c *)
    let (b0,v0) = if wl=wl1 then wl2 else wl1 in (* le littéral qu'on veut conserver *)
    match super#get_pari v0 with (* on regarde si le littéral qu'on garde est à vrai, faux ou indéterminé *)
      | None -> 
          begin
            try
              c#get_vpos#iter (fun var -> if (var<>v0 && super#get_pari var <> Some false) then raise (WL_found (true,var)) else ()) ;
              c#get_vneg#iter (fun var -> if (var<>v0 && super#get_pari var <> Some true) then raise (WL_found (false,var)) else ()) ;
              WL_Assign (b0,v0) (* on ne peut pas déplacer la jumelle mais on peut assigner l'autre littéral *)
            with
              | WL_found l -> 
                  self#watch c l wl ; 
                  WL_New l (* on peut déplacer la jumelle *) 
          end
      | Some b ->
          begin
            if (b=b0) then (* alors (b0,v0) est vrai dans c *) 
              WL_Nothing (* on n'a rien à faire *)
            else (* (b0,v0) est faux dans c *)
              try
                c#get_vpos#iter (fun var -> if (var<>v0 && super#get_pari var <> Some false) then raise (WL_found (true,var)) else ());
                c#get_vneg#iter (fun var -> if (var<>v0 && super#get_pari var <> Some true) then raise (WL_found (false,var)) else ());
                WL_Conflit (* on ne peut pas déplacer la jumelle et l'autre littéral est faux*)
              with
                | WL_found l -> 
                    self#watch c l wl; 
                    WL_New l (* on peut déplacer la jumelle *)
          end



          






end




