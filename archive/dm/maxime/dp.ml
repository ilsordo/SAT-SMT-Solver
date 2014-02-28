open Seau
open Clause

type result = No_solution | Solution of bool array

let solve cnf n =
  let seaux = Array.init n (fun k -> new seau (k+1)) in
  let rec dispatch = function
    | [] -> ()
    | []::_ -> raise Empty_clause
    | ((_,x)::_ as clause)::q -> 
        seaux.(x-1)#add clause; 
        dispatch q in
  try 
    (*Printf.printf "c cnf :\n%a\n%!" print_cnf cnf;*)
    dispatch cnf;
    for i = n-1 downto 0 do
      seaux.(i)#resolve seaux
    done;
    let res = Array.make n false in
    for i = 0 to n-1 do
      seaux.(i)#assign res
    done;
    assert(List.for_all (eval_clause res) cnf);
    Solution(res)
  with
    | Empty_clause -> No_solution
    | e -> raise e

let print_solution valeurs = 
  let print = Printf.printf in
  match valeurs with
    | No_solution -> print "s UNSATISFIABLE\n%!"
    | Solution valeurs ->
        print "s SATISFIABLE\n";
        for i = 0 to (Array.length valeurs)-1 do
          print "v ";
          if not valeurs.(i) then
            print "-";
          print "%d\n" (i+1)
        done;
        print "%!"
          


















