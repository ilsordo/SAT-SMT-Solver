open Formule
open Printf
open Debug

type t = Unsolvable | Solvable of bool vartable*(out_channel -> unit)

let check n cnf = function
  | Unsolvable -> ()
  | Solvable valeurs ->
      let f_verif = new formule in
      f_verif#init n cnf;
      valeurs#iter (fun v b -> f_verif#set_val b v 0);
      debug#p 1 "Check : %B\n%!" f_verif#eval

let print_answer p = function
  | Unsolvable -> fprintf p "s UNSATISFIABLE\n"
  | Solvable (values, print_result) -> fprintf p "s SATISFIABLE\n%t%!"
