{
  open Difference_parser
}

rule token = parse
  | [' ' '\t' '\n' '\r'] 			{ token lexbuf }   

  | '('						{ LPAREN }  
  | ')'						{ RPAREN } 
   
  | "\\/"					{ OR }
  | '~'					        { NOT }
  | "=>"					{ IMP }
  | "<=>"				        { EQU }
  | "/\\"					{ AND }

  | '='                                         { EQ }
  | "!="                                        { NEQ }
  | ">="                                        { GEQ }
  | "<="                                        { LEQ }
  | '>'                                         { GT }
  | '<'                                         { LT }

  | [ '0'-'9' ]+ as n                           { INT (int_of_string n) }
  | ['a'-'z']['a'-'z' '0'-'9']* as s            { VAR s }

  | '-'                                         { DIFF }
  
  | eof                                         { EOF }

