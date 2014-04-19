type problem = Cnf | Color of int | Tseitin

type config = 
    { 
      mutable problem_type : problem;
      mutable print_cnf : out_channel option;
      mutable input : string option; 
      mutable algo : Algo.t; 
      mutable nom_algo : string;
      mutable heuristic : Heuristic.t;
      mutable clause_learning : bool;
      mutable nom_heuristic : string
    }

val config : config

val parse_args : unit -> unit
  
val get_input : unit -> in_channel


















