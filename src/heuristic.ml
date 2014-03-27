open Formule

type t = formule -> Clause.literal option

type pol = Formule.formule -> Clause.variable -> bool

let polarite_rand _ _ = Random.bool() (* prochaine polarite = booleen aleatoire *)

let polarite_most_frequent formule x = (* prochaine polarite = celle qui permet de rendre le plus de clauses vraies (via x) *)
  if formule#get_nb_occ true x > formule#get_nb_occ false x then
    true
  else
    false

let next polarite formule = (* prochaine variable = plus grande variable disponible *)
  let n = formule#get_nb_vars in
  let rec parcours_paris = function
    | 0 -> None
    | m -> 
        if (formule#get_pari m != None) then 
          parcours_paris (m-1) 
        else 
          Some (polarite formule m, m) in
  parcours_paris n


let rand polarite formule = (* prochaine variable = variable aleatoire *)
  let n = formule#get_nb_vars in
  let count = formule#get_paris#size in
  if count = n then 
    None
  else
    let rec find_pari i k =
      match formule#get_paris#find i with
        | None -> 
            if k=0 then
              Some (polarite formule i,i)
            else
              find_pari (i-1) (k-1)
        | Some _ -> find_pari (i-1) k in
    find_pari n (Random.int (n-count))



    
(* Max par rapport au premier membre, priorité au premier *)
let max_v (x1,v1) (x2,v2) = if x1>=x2 then (x1,v1) else (x2,v2)

let moms (formule:formule) = (* prochain litteral : celui qui apparait le plus dans les clauses de taille min *)
  let n = formule#get_nb_vars in
  if formule#get_paris#size = n then
    None
  else
    let rec min_clauses (c:Clause.clause) (min_size, elements) = (* ajoute c à elements si elle est de taille min_size. Si de taille < min_size, vide elements et y ajoute c *)
      if formule#clause_current_size c < min_size then
        let elements = new clauseset in
        elements#add c;
        (formule#clause_current_size c, elements)
      else
        begin
          if formule#clause_current_size c = min_size then
            elements#add c;
          (min_size,elements)
        end in
    let (_,elements) = (* elements contient les clauses de taille min *)
      formule#get_clauses#fold min_clauses (max_int, new clauseset) in
    let count_occ (b,v) (c:Clause.clause) n = 
      if c#mem b v then 
        (n+1) 
      else 
        n in
    let rec max_occ (max, lit) = function
      | 0 -> lit
      | v when formule#get_pari v <> None -> max_occ (max, lit) (v-1)
      | v -> 
          let pos = elements#fold (count_occ (true,v)) 0 in
          let neg = elements#fold (count_occ (false,v)) 0 in
          let (max',lit') = max_v (pos,(true,v)) (neg,(false,v)) in
          let (max, lit) = max_v (max',lit') (max,lit) in
          max_occ (max, lit) (v-1) in
    let lit = max_occ (0,(false,0)) n in
    assert (snd lit <> 0); (* Should not happen *)
    Some lit
    


let dlis (formule:formule) = (* prochain litteral : celui qui rend le plus de clauses vraies *)
  let n = formule#get_nb_vars in
  if formule#get_paris#size = n then
    None
  else
    let rec most_eff (max,lit) = function
      | 0 -> lit
      | v when formule#get_pari v <> None -> most_eff (max,lit) (v-1) 
      | v -> 
          let pos = formule#get_nb_occ true v in
          let neg = formule#get_nb_occ false v in
          let (max',lit') = 
            if pos>neg then 
              (pos,(true,v)) 
            else 
              (neg,(false,v)) in
          let (max, lit) = 
            if max'>=max then
              (max',lit')
            else 
              (max,lit) in      
          most_eff (max, lit) (v-1) in      
    let lit = most_eff (0,(false,0)) n in
    assert (snd lit <> 0); (* Should not happen *)
    Some lit       


let jewa (formule:formule) =
  let n = formule#get_nb_vars in
  if formule#get_paris#size = n then
    None
  else
    let scores_pos = new vartable 0 in
    let scores_neg = new vartable 0 in
    let add pol w v =
      if formule#get_pari v = None then
        let scores = if pol then scores_pos else scores_neg in
        match scores#find v with
          | None -> scores#set v w
          | Some s -> scores#set v (s+.w) in
    for v = 1 to n do
      add true 0. v;
      add false 0. v
    done;
    formule#get_clauses#iter 
      (fun c ->
        let w = 2. ** (-. (float_of_int (formule#clause_current_size c))) in
        c#get_vpos#iter (add true w);
        c#get_vneg#iter (add false w)
      );
    let (_,lit) = scores_pos#fold
      (fun v w curr -> max_v (w,(true,v)) curr) 
      (scores_neg#fold 
         (fun v w curr -> max_v (w,(false,v)) curr) 
         (0.,(false,0)) (* pourquoi tu avais marqué (false,-1) *)
      ) in
    assert (snd lit <> 0); (* Should not happen *)
    Some lit    
    
let dlcs polarite formule = (* prochaine variable : la plus fréquente *)
  let n = formule#get_nb_vars in
  if formule#get_paris#size = n then
    None
  else
    let rec most_eff (max,var) = function
      | 0 -> var
      | v when formule#get_pari v <> None -> most_eff (max,var) (v-1) 
      | v -> 
          let pres = (formule#get_nb_occ true v) + (formule#get_nb_occ false v) in
          let (max, var) = 
            if pres>=max then
              (pres,v)
            else 
              (max,var) in      
          most_eff (max, var) (v-1) in      
    let var = most_eff (0,0) n in
    assert (var <> 0); (* Should not happen *)
    Some (polarite formule var,var)
       
