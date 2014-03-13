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
