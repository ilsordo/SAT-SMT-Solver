open Formule
open Printf
open Debug

type t = Unsolvable | Solvable of bool vartable*(out_channel -> unit)

let check n cnf = function
  | Unsolvable -> ()
  | Solvable (valeurs,_) ->
      let f_verif = new formule in
      f_verif#init n cnf;
      valeurs#iter (fun v b -> f_verif#set_val b v 0);
      debug#p 1 "Check : %B\n%!" f_verif#eval
