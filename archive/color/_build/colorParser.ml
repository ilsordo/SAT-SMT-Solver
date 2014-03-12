type token =
  | INT of (int)
  | EDGE
  | EOF

open Parsing;;
let yytransl_const = [|
  258 (* EDGE *);
    0 (* EOF *);
    0|]

let yytransl_block = [|
  257 (* INT *);
    0|]

let yylhs = "\255\255\
\001\000\002\000\003\000\003\000\000\000"

let yylen = "\002\000\
\002\000\003\000\004\000\000\000\002\000"

let yydefred = "\000\000\
\000\000\000\000\000\000\005\000\000\000\000\000\001\000\000\000\
\002\000\000\000\000\000\003\000"

let yydgoto = "\002\000\
\004\000\005\000\009\000"

let yysindex = "\255\255\
\000\255\000\000\001\255\000\000\003\000\002\255\000\000\004\255\
\000\000\005\255\002\255\000\000"

let yyrindex = "\000\000\
\000\000\000\000\000\000\000\000\000\000\007\000\000\000\000\000\
\000\000\000\000\007\000\000\000"

let yygindex = "\000\000\
\000\000\000\000\253\255"

let yytablesize = 8
let yytable = "\001\000\
\003\000\006\000\007\000\008\000\010\000\011\000\004\000\012\000"

let yycheck = "\001\000\
\001\001\001\001\000\000\002\001\001\001\001\001\000\000\011\000"

let yynames_const = "\
  EDGE\000\
  EOF\000\
  "

let yynames_block = "\
  INT\000\
  "

let yyact = [|
  (fun _ -> failwith "parser")
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 1 : 'color_formule) in
    Obj.repr(
# 15 "colorParser.mly"
                                    ( _1 )
# 64 "colorParser.ml"
               : (int*int*((int*int) list))))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 2 : int) in
    let _2 = (Parsing.peek_val __caml_parser_env 1 : int) in
    let _3 = (Parsing.peek_val __caml_parser_env 0 : 'edges) in
    Obj.repr(
# 19 "colorParser.mly"
                             ( (_1,_2,_3) )
# 73 "colorParser.ml"
               : 'color_formule))
; (fun __caml_parser_env ->
    let _2 = (Parsing.peek_val __caml_parser_env 2 : int) in
    let _3 = (Parsing.peek_val __caml_parser_env 1 : int) in
    let _4 = (Parsing.peek_val __caml_parser_env 0 : 'edges) in
    Obj.repr(
# 23 "colorParser.mly"
                              ( (_2,_3)::_4)
# 82 "colorParser.ml"
               : 'edges))
; (fun __caml_parser_env ->
    Obj.repr(
# 24 "colorParser.mly"
                              ( [] )
# 88 "colorParser.ml"
               : 'edges))
(* Entry main *)
; (fun __caml_parser_env -> raise (Parsing.YYexit (Parsing.peek_val __caml_parser_env 0)))
|]
let yytables =
  { Parsing.actions=yyact;
    Parsing.transl_const=yytransl_const;
    Parsing.transl_block=yytransl_block;
    Parsing.lhs=yylhs;
    Parsing.len=yylen;
    Parsing.defred=yydefred;
    Parsing.dgoto=yydgoto;
    Parsing.sindex=yysindex;
    Parsing.rindex=yyrindex;
    Parsing.gindex=yygindex;
    Parsing.tablesize=yytablesize;
    Parsing.table=yytable;
    Parsing.check=yycheck;
    Parsing.error_function=parse_error;
    Parsing.names_const=yynames_const;
    Parsing.names_block=yynames_block }
let main (lexfun : Lexing.lexbuf -> token) (lexbuf : Lexing.lexbuf) =
   (Parsing.yyparse yytables 1 lexfun lexbuf : (int*int*((int*int) list)))
