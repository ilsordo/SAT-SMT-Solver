open Formule

type answer = Unsolvable | Solvable of bool vartable

let print_valeur p v = function (* affichage d'une variable et de sa valeur *)
  | true -> Printf.fprintf p "v %d\n" v
  | false -> Printf.fprintf p "v -%d\n" v

let print_answer p = function (* affichage du résultat final *)
  | Unsolvable -> Printf.fprintf p "s UNSATISFIABLE\n"
  | Solvable valeurs -> 
      Printf.fprintf p "s SATISFIABLE\n";
      for v=1 to valeurs#size do
        match valeurs#find v with
          | None -> assert false
          | Some b -> print_valeur p v b
      done


