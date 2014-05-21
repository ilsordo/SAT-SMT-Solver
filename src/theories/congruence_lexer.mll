{
  open Congruence_parser
}

rule token = parse
  | [' ' '\t' '\n' '\r'] 			{ token lexbuf }   

  | '('						{ LPAREN }  
  | ')'						{ RPAREN } 
   
  | "\\/"					{ OR }
  | '~'		        { NOT }
  | "=>"	    		{ IMP }
  | "<=>"	        { EQU }
  | "/\\"					{ AND }

  | '='           { EQ }
  | "!="          { NEQ }
  | ','           { SEP }      

  | ['a'-'w' 'y' 'z']['a' - 'z']* as s 	        { FUN s }
  | 'x'['0'-'9']+ as s                          { VAR s }
  
  | eof                                         { EOF }


