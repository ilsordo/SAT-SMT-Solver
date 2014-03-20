open Formule
open Printf
open Debug

type t = Unsolvable | Solvable of bool vartable

let check n cnf = function
  | Unsolvable -> ()
  | Solvable valeurs ->
      let f_verif = new formule in
      f_verif#init n cnf;
      valeurs#iter (fun v b -> f_verif#set_val b v);
      debug 1 "Check : %B\n%!" f_verif#eval

let print_valeur p v = function (* affichage d'une variable (int) et de sa valeur *)
  | true -> fprintf p "v %d\n" v
  | false -> fprintf p "v -%d\n" v

let print_answer p = function
  | Unsolvable -> fprintf p "s UNSATISFIABLE\n"
  | Solvable values -> 
      fprintf p "s SATISFIABLE\n";
      values#iter (print_valeur p)
