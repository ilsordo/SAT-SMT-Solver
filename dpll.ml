open Formule

(*
type mem = (variable*(variable list)) list
*)

let next_pari formule = (* Some v si on doit faire le prochain pari sur v, None si tout a été parié (et on a donc une affectation gagnante) *)
  let n=formule#get_nb_vars in (** pas de fonction get_nb_vars *)
  let rec parcours_paris m = 
    if m > n
    then None
    else if formule#is_pari m 
         then parcours_paris (m+1) 
         else Some m
  in parcours_paris 1


(*
class mem n =
object
  val valeurs : bool option array = Array.make (n+1) None
  method affect l =
    let v = Array.copy valeurs in
    List.iter (fun (x,b) -> v.(x) <- Some b) l; 
    {< valeurs = v >}
      
  method is_free x = 
    match valeurs.(x) with
      | Some _ -> false
      | None -> true
          
  method get_valeurs = Array.copy valeurs
end
*)



let constraint_propagation v b formule = (* on affecte v et on propage, on renvoie les variables affectées + false si une clause vide a été générée, true sinon*)
  let var_add=ref [v] in
  let stop=ref 0 in
   if formule#set_val b v
   then
     begin 
        while (!stop = 0) do
          let l=formule#find_singleton in
            begin
             if (l=[])
             then stop:=1
             else List.iter (fun x -> match x with
                                        | None -> assert false
                                        | Some(vv,bb) -> if not (!stop = 2)
                                                         then 
                                                           begin
                                                             var_add := vv::(!var_add);
                                                             if not (formule#set_val bb vv)
                                                             then stop:=2
                                                           end)
                            l
            end;
          if not (!stop = 2)
            then match formule#find_single_polarite with
              | None -> ()
              | Some (vv,bb) -> begin
                                  stop:=0;
                                  var_add := vv::(!var_add);
                                  if not (formule#set_val bb vv)
                                  then stop:=2
                                end
        done;
        if (!stop = 1)
        then (!var_add,true)
        else (!var_add,false)
     end
   else (!var_add,false)






let dpll formule = (* renvoie true si une affectation a été trouvée, stockée dans paris, false sinon *)
  let rec aux v b = (* faire le pari b sur v *) (*renvoie true si on peut prolonger les paris actuels, plus (v,b), en qqchose de satisfiable *)
    match constraint_propagation v b formule with
      | (var_add,false) -> List.iter (fun vv -> formule#reset_val vv) var_add; (* on annule les paris faits *)
                           if b then aux v false
                                else false
      | (var_add,true) -> match next_pari formule with
                            | None -> true
                            | Some vv -> if aux vv true
                                         then true
                                         else 
                                          begin
                                              List.iter (fun vv -> formule#reset_val vv) var_add;
                                              if b 
                                              then aux v false
                                              else false
                                          end
  in aux 1 true


(* Réflexions : *)
(* si b est false, on va fusionner des listes *)
(* on met le pari en tête de mem *)
(** ce n'est pas rec terminal *)
(* tous les paris ont été enlevés ? *)
(** détection des tautologies / inclusions *)
  














