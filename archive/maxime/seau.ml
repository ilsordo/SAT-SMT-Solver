open Clause

exception Empty_clause

module ClauseSet = Set.Make(
  struct
    type t = clause
    let compare = compare
  end)

class seau k =
object
  (* Le seau contient des clauses dont les variables sont >=k, on enlève le premier littéral qui est k ou -k *) 
  val mutable pos = ClauseSet.empty
  val mutable neg = ClauseSet.empty 
  
  method add = function
    | [] -> raise (Invalid_argument "Clause vide")
    | (_,x)::_ when x<>k -> raise (Invalid_argument "Mauvaise variable en tête")
    | (_,x)::(_,y)::q when x=y ->
       () (* k ou -k *)
    | (true,_)::q -> 
        pos <- ClauseSet.add q pos
    | (false,_)::q -> 
        neg <- ClauseSet.add q neg

  (* Fait déborder toutes les résolutions du seau *)
  method resolve (seaux : seau array) =
    Printf.printf "c > seau %d\n%!" k;
    ClauseSet.iter
      (fun c_pos ->
        ClauseSet.iter
          (fun n_pos ->
            match merge c_pos n_pos with
              | [] -> raise Empty_clause
              | ((_,x)::q) as clause -> seaux.(x-1)#add clause
          )
          neg
      )
      pos

  (* Si la formule est satisfiable et valeurs.(0..k-1) peuvent satisfaire ce qui est dans les seaux 0..k-1
     alors on trouve une valeur de la k-ième variable qui satisfait le seau *)
  method assign valeurs =
    let valeur =
      if ClauseSet.is_empty pos then
        false
      else 
        if ClauseSet.is_empty neg then
          true
        else
          not (ClauseSet.for_all (eval_clause valeurs) pos) in
    (*Printf.printf "c < seau %d\n%!" k;*)
    valeurs.(k-1) <- valeur (* Si l'une des clauses positives n'est pas déjà satisfaite on met la variable à vrai*)
 
end



















