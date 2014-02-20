open Clause

module ClauseSet = Set.Make(OrderedClause)

type f_repr = ClauseSet.t

class clauseset =
object
  val mutable vis = ClauseSet.empty
  val mutable hid = ClauseSet.empty
    
  method repr = vis

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
  val data : (variable*'a) Hashtbl.t = Hashtbl.create n
    
  method size = Hashtbl.length data

  method set v x = Hashtbl.replace data v x

  method mem v = try Some (Hashtbl.find data v) with Not_found -> None

  method remove v = Hashtbl.remove data v

  method iter f = Hashtbl.iter f data
end


class formule n clauses_init =
object (self)
  val clauses = new clauseset
  val occurences_pos = new [clauseset] vartable n
  val occurences_neg = new [clauseset] vartable n

  initializer
    List.iter (fun c -> clause#add (new clause c)) clauses_init;
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

  method get_occurences b v =
    if b then
      occurences_pos#mem v
    else
      occurences_neg#mem v

  method add_clause c =
    clauses#add c;
    self#register_clause c

  method get_clauses = clauses

  method set_val b v = 
    let (valider,supprimer) =
      if b then
        (occurences_pos,occurences_neg)
      else
        (occurences_neg,occurences_pos) in
    begin
      match supprimer#get v with
        | None -> ()
        | Some occurences -> occurences#iter (fun c -> c#hide_var (not b) v)
    end;
    begin
      match valider#get v with
        | None -> ()
        | Some occurences -> occurences#iter (fun  c -> clauses#hide c) 
    end

  method reset x =
    ClauseSet.iter
      (fun c -> x#hide_var_neg x)
      occurences_neg.(x);
    clauses <- ClauseSet.diff clauses occurences_pos.(x);
    clauses_hidden <- ClauseSet.union clauses_hidden occurences_pos.(x)
      
      
(*method set_val k b = valeur.(k) <- Some b

  method unset k = valeur.(k) <- None
  
  method get_val k = valeur.(k)*)

  method remove_clause c = 
    clauses <- ClauseSet.remove c clauses;
    ClauseSet.iter (fun v -> ClauseSet.remove c occurences_pos.(v)) c#get_vpos;
    ClauseSet.iter (fun v -> ClauseSet.remove c occurences_neg.(v)) c#get_vneg

(*   
     method fusion_clauses (c1:clause) (c2:clause) (vv : variable) = 
     let c = new clause in (* c est la fusion des clauses c1 et c2 suivant la variable vv *)
     clauses <- ClauseSet.add c clauses;
     VarSet.iter (fun v -> c#add_vpos v) c1#get_vpos ;
     VarSet.iter (fun v -> c#add_vneg v) c1#get_vneg ;
     VarSet.iter (fun v -> c#add_vpos v) c2#get_vpos ;
     VarSet.iter (fun v -> c#add_vneg v) c2#get_vneg ;		
     c#remove_var vv; (* on supprime vv de c, car la fusion s'est effectuée selon vv *)						
     c	(* on renvoie c *)
*) 

(* method eval_clause c = (* indique si la clause c est vraie avec les valeurs actuelles *)
   (VarSet.exists 
   (fun v -> match (self#get_val v) with 
   | Some b -> b 
   | None -> false )  
   c#get_vpos) || 
   (VarSet.exists 
   (fun v -> match (self#get_val v) with 
   | Some b -> not b 
   | None -> false ) 
   c#get_vneg)  *)


end
