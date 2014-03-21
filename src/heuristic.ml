open Formule

type t = formule -> Clause.literal option

type pol = Formule.formule -> Clause.variable -> bool

let polarite_rand _ _ = Random.bool()

let polarite_most_frequent formule x =
  if formule#get_nb_occ true x > formule#get_nb_occ false x then
    true
  else
    false

let next polarite formule = 
  let n = formule#get_nb_vars in
  let rec parcours_paris = function
    | 0 -> None
    | m -> 
        if (formule#get_pari m != None) then 
          parcours_paris (m-1) 
        else 
          Some (polarite formule m, m) in
  parcours_paris n


(* Bug *)
let rand polarite formule =
  let n = formule#get_nb_vars in
  let count = formule#get_paris#size in
  if count = n then 
    None
  else
    (* Traverse k variables libres à partir de i*) 
(*  let rec find_pari i = function
      | 0 -> Some (polarite formule i,i) (* qd on a atteint 0, on doit prendre la prochaine var libre disponible, qui n'a pas de raison d'être i *)
      | k -> 
          Debug.debug 1 "Rand %d" k;
          match formule#get_paris#find k with
            | None -> find_pari (i+1) (k-1) (* prq i+1 alors que tu commences avec i=n ? *)
            | Some _ -> find_pari (i+1) k in (* idem *)
    find_pari n (Random.int (n-count))
*)
    let rec find_pari i k =
      match formule#get_paris#find i with
        | None -> 
            if k=0 then
              Some (polarite formule i,i)
            else
              find_pari (i-1) (k-1)
        | Some _ -> find_pari (i-1) k in
    find_pari n (Random.int (n-count))
    
    
let moms (formule:formule) = 
  let n = formule#get_nb_vars in
  if formule#get_paris#size = n then
    None
  else
    let rec min_clauses (c:Clause.clause) (min_size, elements) =
      if c#size < min_size then
        let elements = new clauseset in
        elements#add c;
        (c#size, elements)
      else
        begin
          if c#size = min_size then
            elements#add c;
          (min_size,elements)
        end in
    let (_,elements) = 
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
          let (max',lit') = 
            if pos>neg then 
              (pos,(true,v)) 
            else 
              (neg,(false,v)) in
          let (max, lit) = 
            if max'>max then
              (max',lit') 
            else 
              (max,lit) in
          max_occ (max, lit) (v-1) in
    let lit = max_occ (0,(false,0)) n in
    assert (snd lit <> 0); (* Should not happen *)
    Some lit
