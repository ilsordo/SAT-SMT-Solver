{
  open Congruence_parser
}

rule token = parse
  | [' ' '\t' '\n' '\r'] 			{ token lexbuf }   

  | '('						{ LPAREN }  
  | ')'	          { RPAREN } 
   
  | "\\/"         { OR }
  | '~'		        { NOT }
  | "=>"          { IMP }
  | "<=>"	        { EQU }
  | "/\\"					{ AND }

  | '='           { EQ }
  | "!="          { NEQ }
  | ','           { SEP }      

  | (['a'-'z']['a'-'z' '1'-'9' '_']* as s)(' '*)'(' { FUN s }
  | (['a'-'z']['a'-'z' '1'-'9' '_']* as s)          { VAR s }
  
  | eof                                             { EOF }


