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
  exit 0

let _ = main()

