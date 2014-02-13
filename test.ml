open Clause

module IntSet = Set.Make(
  struct
    type t = int
    let compare = compare
  end)

let test_link n =
  let rec aux acc = function 
    | 0 -> acc
    | i -> aux ([(true,i);(false,i+1)]::acc) (i-1) in
  aux [] (max 0 (n-1))

let test_random vars c_size c_num =
  Random.self_init();
  let rec random_lit seen =
    let x = (Random.int vars) + 1 in
    if not (IntSet.mem x seen) then
      (Random.bool(),x)
    else
      random_lit seen in
  let rec random_clause seen acc = function
    | 0 -> acc
    | i -> 
        let (b,x) = random_lit seen in
        let new_seen = IntSet.add x seen in
        random_clause new_seen ((b,x)::acc) (i-1) in
  let rec random_cnf acc = function
    | 0 -> acc
    | i -> random_cnf (random_clause IntSet.empty [] c_size::acc) (i-1) in
  random_cnf [] c_num
   














