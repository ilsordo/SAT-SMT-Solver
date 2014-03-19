open Formule

type pari = formule -> Clause.litteral option


let polarite_rand _ _ = Random.bool()

let polarite_most_frequent formule x =
  if (formule#get_nb_occ true x)#size > (formule#get_nb_occ false x)#size then
    true
  else
    false

let next polarite formule = 
  let n=formule#get_nb_vars in
  let rec parcours_paris = function
    | 0 -> None
    | m -> 
        if (formule#get_pari m != None) then 
          parcours_paris (m-1) 
        else 
          Some (polarite formule m, m) in
  parcours_paris n

let rand_aux polarite formule =
  let n = formule#get_nb_vars in
  let count = formule#get_paris#get_size in
  if count = n then 
    None
  else
    (* Traverse k variables libres à partir de i*) 
    let rec find_pari i = function
      | 0 -> Some (polarite formule i,i)
      | k -> 
          match formule#get_paris#find v with
            | None -> find_pari (i+1) (k-1)
            | Some _ -> find_pari (i+1) k in 
    find_pari 0 (Random.int count + 1)

















