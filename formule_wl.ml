open Clause
open Formule
open Debug

exception Found of (variable*bool)

type wl_update = WL_Conflit 

exception WLs_found of literal_wl*literal_wl

class formule_wl =
object
  inherit formule as super

  val wl_pos : clauseset vartable = new vartable 0
  val wl_neg : clauseset vartable = new vartable 0

  method init n clauses_init =
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

(* Initialise les watched literals des clauses, il faut vérifier qu'il n'y a pas de clause vide *)
  method init_wl =
    let pull b temp v = (* Extrait 2 éléments *)
      match temp with None -> Some (Some b,v) | Some l -> raise WLs_found (l,(Some b, v)) in
    clauses#iter
      (fun c -> 
        try 
          c#get_vpos#fold (pull true) (c#get_vneg#fold (pull false) None);
          assert false 
        with
          | WL_found (l1,l2) ->
              self#register c l1;
              self#register c l2;
              c#set_wl1 l1;
              c#set_wl2 l2)

  method private update_clause c =
    

end
