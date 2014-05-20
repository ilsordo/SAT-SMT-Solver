open Smt_base
open Algo_base

type problem = Cnf | Color of int | Smt of ( module Smt_base )

type config = 
    { 
      mutable problem_type : problem;
      mutable print_cnf : out_channel option;
      mutable input : string option; 
      mutable algo : (module Algo_base);
      mutable heuristic : Heuristic.t;
      mutable nom_heuristic : string;
      mutable clause_learning : bool;
      mutable interaction : bool
    }

val config : config

val parse_args : unit -> unit
  
val get_input : unit -> in_channel


















