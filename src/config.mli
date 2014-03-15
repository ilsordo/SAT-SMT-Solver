type problem = Cnf | Color of int | Tseitin

type config = 
    { 
      mutable problem_type : problem;
      mutable print_cnf : bool;
      mutable input : string option; 
      mutable algo : int -> int list list -> Answer.answer; 
      mutable nom_algo : string 
    }

val config : config

val parse_args : unit -> unit
  
val get_input : unit -> in_channel


















