type token =
  | INT of (int)
  | EDGE
  | EOF

val main :
  (Lexing.lexbuf  -> token) -> Lexing.lexbuf -> (int*int*((int*int) list))
