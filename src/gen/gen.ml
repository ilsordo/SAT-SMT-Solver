let parse_args () =
  let args = Sys.argv in
  let parse_int i = int_of_string args.(i) in
  if Array.length args > 1 then
    match (args.(1), Array.length args) with
      | "-color", 4 -> Gcolor.gen (parse_int 2) (float_of_string args.(3))
      | "-tseitin", 4 -> Gtseitin.gen (parse_int 2) (parse_int 3)
      | "-cnf", 5 -> Gcnf.gen (parse_int 2) (parse_int 3) (parse_int 4)
      | _, 5 -> Gcnf.gen (parse_int 1) (parse_int 2) (parse_int 3)
      | _ -> Printf.eprintf "Usage : gen -[cnf|color|tseitin] parametres\n%!"; exit 1

let main () =
  Random.self_init();
  parse_args ();
  exit 0

let _ = main()
