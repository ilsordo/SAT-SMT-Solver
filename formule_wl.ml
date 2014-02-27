open Clause
open Formule
open Debug

exception Found of (variable*bool)

type wl_update = WL_Conflit | WL_New | WL_Assign of literal | WL_Nothing

exception WLs_found of (literal*literal)

exception WL_found of literal

class formule_wl =
object(self)
  inherit formule as super

  val wl_pos : clauseset vartable = new vartable 0
  val wl_neg : clauseset vartable = new vartable 0

  method get_wl_pos var = (* à fusionner avec fonction get_wl plus bas *)
    match wl_pos#find var with
      | None -> assert false (* aurait du être initialisé *)
      | Some s -> s

  method get_wl_neg var = (* à fusionner avec fonction get_wl plus bas *)
    match wl_neg#find var with
      | None -> assert false (* aurait du être initialisé *)
      | Some s -> s

  method get_wl v dest =
    match dest#find v with
      | None -> 
          let set = new clauseset in
          dest#set v set;
          set
      | Some set -> set

  method private register c = function
    | (true,v) -> (self#get_wl v wl_pos)#add c
    | (false,v) -> (self#get_wl v wl_neg)#add c


  method watch c l l_former = (* on veut que le litteral l surveille la clause c, à la place de l_former *) (*** ce code peut contenir des bugs mineurs *)
    let (b,v)=l in
    let (b_former,v_former)=l in
    if b then
      (self#get_wl v wl_pos)#add c (* l sait qu'il surveille c *)
    else
      (self#get_wl v wl_neg)#add c; (* l sait qu'il surveille c *)
    let (wl1,wl2) = c#get_wl in
      if l_former=wl1 then
        begin
          c#set_wl1 l; (* c sait qu'il est surveillé par l *)
          if b_former then
            (self#get_wl v_former wl_pos)#remove c (* l_former sait qu'il ne surveille plus c *)
          else
            (self#get_wl v_former wl_neg)#remove c (* l_former sait qu'il ne surveille plus c *)
        end
      else
        begin
          c#set_wl2 l; (* c sait qu'il est surveillé par l *)
          if b_former then
            (self#get_wl v_former wl_pos)#remove c (* l_former sait qu'il ne surveille plus c *)
          else
            (self#get_wl v_former wl_neg)#remove c (* l_former sait qu'il ne surveille plus c *)
        end

  method init n clauses_init = (* après un appel initial à init, il faudra supprimer les clauses vides *)
    for i=1 to n do (***)
      wl_pos#set i (new clauseset);
      wl_neg#set i (new clauseset)
    done;
    super#init n clauses_init;
    let (occ_pos,occ_neg) = (new vartable n, new vartable n) in
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
    clauses#iter register_clause;
    let get_occurences occ var = 
      match occ#find var with
        | None -> new clauseset
        | Some occurences -> occurences in
    let rec prepare () =
      let res = 
        try 
          clauses#iter (fun c -> match c#singleton with Some s -> raise (Found s) | None -> ());
          None
        with Found s -> Some s in
      match res with
        | None -> ()
        | Some (v,b) ->
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


(* Initialise les watched literals des clauses, il faut enlever avant les clauses vides *)
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
              self#register c l1;
              self#register c l2;
              c#set_wl1 l1;
              c#set_wl2 l2)

  method update_clause c wl = (* on veut abandonner la jumelle sur le literal wl*)
    let (wl1,wl2) = c#get_wl in
    (*let (b,v) = wl in*) (* c'est (b,l) qu'on veut abandonner *)
    let (b0,v0) = if wl=wl1 then wl2 else wl1 in (* le literal qu'on veut conserver *)
    match super#get_pari v0 with
      | None -> 
          begin
            try
              c#get_vpos#iter (fun var -> if (var != v0 && super#get_pari var != Some false) then raise (WL_found (true,var)) else ()) ;
              c#get_vneg#iter (fun var -> if (var != v0 && super#get_pari var != Some true) then raise (WL_found (false,var)) else ()) ;
              WL_Assign (b0,v0) (* on ne peut pas déplacer la jumelle mais on peut assigner l'autre literal *)
            with
              | WL_found l -> (self#watch c l wl ; WL_New) (* on peut déplacer la jumelle *) 
          end
      | Some b ->
          begin
           if (b=b0) (* alors (b0,v0) est vrai dans c *) then 
            try
                c#get_vpos#iter (fun var -> if (var != v0 && super#get_pari var != Some false) then raise (WL_found (true,var)) else ());
                c#get_vneg#iter (fun var -> if (var != v0 && super#get_pari var != Some true) then raise (WL_found (false,var)) else ());
              WL_Nothing (* on ne peut pas déplacer la jumelle mais l'autre literal est déjà vrai *)
            with
                | WL_found l -> (self#watch c l wl ; WL_New) (* on peut déplacer la jumelle *)
            else (* (b0,v0) est faux dans c *)
              try
                c#get_vpos#iter (fun var -> if (var != v0 && super#get_pari var != Some false) then raise (WL_found (true,var)) else ());
                c#get_vneg#iter (fun var -> if (var != v0 && super#get_pari var != Some true) then raise (WL_found (false,var)) else ());
                WL_Conflit (* on ne peut pas déplacer la jumelle et l'autre literal est faux*)
              with
                | WL_found l ->( self#watch c l wl ; WL_New) (* on peut déplacer la jumelle *)
          end












end




