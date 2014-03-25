open Config_random

let main () =
  parse_args();
  Random.self_init();
  match config.random_type with
    | Cnf -> Gcnf.gen ()
    | Tseitin -> Gtseitin.gen ()
    | Color -> Gcolor.gen ()
  ;
  exit 0

let _ = main()

