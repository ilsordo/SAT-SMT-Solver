open Dpll
open Lexing
open Printf

(* Gestion des arguments *)
(*
type input = Stdin | File of string | Test1 of int | Test2 of (int*int*int)

let usage () =
  eprintf "Usage : resol [fichier|-test1 n|-test2 n_vars l_clause n_clause]\nb%!";
  exit 1

let parse_args () =
  match Array.length Sys.argv with
    | 1 -> Stdin
    | 2 -> File (Sys.argv.(1))
    | 3 when Sys.argv.(1)="-test1" ->
        begin
          try
            Test1(int_of_string Sys.argv.(2))
          with
            | Failure _ -> usage()
        end
    | 5 when Sys.argv.(1)="-test2" ->
        begin
          try
            Test2(int_of_string Sys.argv.(2),int_of_string Sys.argv.(3),int_of_string Sys.argv.(4))
          with
            | Failure _ -> usage()
        end
    | _ -> usage() 

let parse_head lexbuf = Parser.head Lexer.head lexbuf

let parse_clauses lexbuf = Parser.main Lexer.token lexbuf

let parse input =
  try
    let lex = Lexing.from_channel input in
    let n = parse_head lex in
    let cnf = parse_clauses lex in
    (n,cnf)
  with
    | Lexer.Error c ->
        eprintf "Symbole illégal : %c\n" c;
        exit 1
    | _ -> 
        eprintf "Input error\n%!";
        exit 1

let rec init_cnf =  function
  | Stdin -> parse stdin
  | File f -> 
      begin
        try 
          parse (open_in f) 
        with 
          | Sys_error s -> 
              eprintf "Error reading f : %s" s;
              exit 1
      end
  | Test1 n -> 
      init_cnf(Test2(n,3,10*n))
  | Test2 (v,c_size,c_num) when v<c_size -> 
      eprintf "Not enough variables";
      exit 1 
  | Test2 (v,c_size,c_num) -> 
      printf "p cnf %d %d\n%a\n%!" v c_num print_cnf (Test.test_random v c_size c_num);
      exit 0

let main () =
  let (n,cnf) = init_cnf (parse_args()) in
  (*Printf.printf "c %d variables\nc cnf :\n%a\n" n print_cnf cnf;*)
  print_solution (solve cnf n);
  exit 0

let _ = main()














*)
