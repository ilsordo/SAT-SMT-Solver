open Formule

type answer = Unsolvable | Solvable of bool vartable

let print_valeur p v = function
  | true -> Printf.fprintf p "v %d\n" v
  | false -> Printf.fprintf p "v -%d\n" v

let print_answer p = function
  | Unsolvable -> Printf.fprintf p "s UNSATISFIABLE\n"
  | Solvable valeurs -> 
      Printf.fprintf p "s SATISFIABLE\n";
      valeurs#iter (print_valeur p)

(*************)

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



let constraint_propagation v b formule = (* on affecte v et on propage, on renvoie la liste des variables affectées + false si une clause vide a été générée, true sinon*)
  let var_add=ref [v] in (* var_add va contenir la liste des variables ayant été affectées *)
  let stop=ref 0 in (* stop = 0 : il y a encore à propager, stop = 1 : on a finit de propoage, stop = 2 : on a généré une clause vide *)
   if formule#set_val b v
   then
     begin 
        while (!stop = 0) do
          let l=formule#find_singleton in (* toute les variables qui forment des clauses singletons *)
            begin
             if (l=[])
             then stop:=1 (* on se donne une chance de finir la propagation *)
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
              | None -> () (* si stop était égale à 1, la propagation s'arrète ici *)
              | Some (vv,bb) -> begin
                                  stop:=0; (* la propagation doit refaire un tour... *)
                                  var_add := vv::(!var_add);
                                  if not (formule#set_val bb vv)
                                  then stop:=2
                                end
        done;
        if (!stop = 1)
        then (!var_add,true)
        else (!var_add,false) (* stop = 2 : clause vide créée *)
     end
   else (!var_add,false)






let dpll formule = (* renvoie true si une affectation a été trouvée, stockée dans paris, false sinon *)
  let rec aux v b = (* renvoie true si en pariant b, ou plus, sur v on peut prolonger les paris actuels en qqchose de satisfiable *)(* "b ou plus" = true et false si b=true, juste false sinon *)
    match constraint_propagation v b formule with
      | (var_add,false) -> List.iter (fun vv -> formule#reset_val vv) var_add; (* on annule les paris faits *)
          if b then aux v false (* si on avait parié true, on retente avec false *)
          else false (* sinon c'est finit, on va devoir revenir en arrière *)
      | (var_add,true) -> match next_pari formule with
          | None -> true (* plus aucun pari à faire, c'est gagner *)
          | Some vv -> if aux vv true (* si on réussit à parier sur vv, puis à prolonger *)
            then true (* alors c'est gagné *)
            else 
              begin
                List.iter (fun vvv -> formule#reset_val vvv) var_add; (* sinon on annule les paris *)
                if b then aux v false (* si on avait parié true, on retente avec false *)
                else false (* sinon on va doit revenir en arrière *)
              end
  in aux 1 true

















