{
  open Tseitin_parser
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

  | ['a'-'z']['a'-'z' '0'-'9']* as s 	        { ATOM s }
  
  | eof                                         { EOF }

