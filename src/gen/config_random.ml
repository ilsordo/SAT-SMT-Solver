open Printf


type random = Cnf | Color | Tseitin

type config = 
    { 
      mutable random_type : random;
      mutable param1 : int;
      mutable param2 : int;
      mutable param3 : int;      
      mutable param4 : float;
      mutable input : string option
    }

let config = 
  { 
    random_type = Cnf;
    param1 = 0;
    param2 = 0;
    param3 = 0;
    param4 = 0.;
    input = None
  }


let parse_args () =
  let use_msg = "Usage:\n resol [file.cnf] [options]\n" in 
       
  let speclist = Arg.align [
    ("-cnf",     Arg.Tuple ([Arg.Int (fun n -> config.param1 <- n ; config.random_type <- Cnf) ; Arg.Int (fun l -> config.param2 <- l) ; Arg.Int (fun k -> config.param3 <- k)]), " n l k");
    ("-tseitin", Arg.Tuple ([Arg.Int (fun n -> config.param1 <- n ; config.random_type <- Tseitin) ; Arg.Int (fun c -> config.param2 <- c)]), " n c");
    ("-color",   Arg.Tuple ([Arg.Int (fun n -> config.param1 <- n ; config.random_type <- Color) ; Arg.Float (fun p -> config.param4 <- p)]), " n p");
  ] in
  
  Arg.parse speclist (fun s -> config.input <- Some s) use_msg
  
  
  
