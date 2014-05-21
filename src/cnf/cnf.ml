open Answer
open Printf

let parse input =
  try
    let lex = Lexing.from_channel input in
    let (n,f) = Parser.main Lexer.token lex in
    (n,f)
  with
    | _ -> 
        Printf.eprintf "Input error\n%!";
        exit 1

let to_cnf c = c

let print_answer p = function
  | Unsolvable -> fprintf p "s UNSATISFIABLE\n"
  | Solvable (values, print_result) -> fprintf p "s SATISFIABLE\n%t%!" print_result
