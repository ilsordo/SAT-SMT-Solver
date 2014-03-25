<<<<<<< HEAD
open Printf

let main () =
  Random.self_init();
  let t = Sys.argv in
    try
      if Array.length t = 4 then
        match t.(1) with
          | "tseitin" -> Random_tseitin.gen (int_of_string t.(2)) (int_of_string t.(3))
          | "color" -> Random_color.gen (int_of_string t.(2)) (float_of_string t.(3))
          | _ -> Random_cnf.gen (int_of_string t.(1)) (int_of_string t.(2)) (int_of_string t.(3))
      else raise (Failure "")
    with Failure _ -> eprintf "Usage : gen [n l k | tseitin n c | color n p]\n%!";
=======
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
>>>>>>> f14adbe7c1ad0ffb1034255cb8faf2e3c872a7e8
  exit 0

let _ = main()
