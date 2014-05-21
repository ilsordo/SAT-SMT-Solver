{
  open Equality_parser
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

  | (['a'-'z']['a'-'z' '1'-'9' '_']* as s)      { VAR s }

  
  | eof                                         { EOF }

