{
  open Congruence_parser
}

rule token = parse
  | [' ' '\t' '\n' '\r'] 			{ token lexbuf }   

  | '('						{ LPAREN }  
  | ')'	                                        { RPAREN } 
   
  | "\\/"               { OR }
  | '~'		        { NOT }
  | "=>"          		{ IMP }
  | "<=>"	        { EQU }
  | "/\\"					{ AND }

  | '='           { EQ }
  | "!="          { NEQ }
  | ','           { SEP }      

  | ['a'-'w' 'y' 'z']['a' - 'z']* as s 	        { Printf.eprintf "Fun %s\n%!" s;FUN s }
  | 'x'['0'-'9']+ as s                          { Printf.eprintf "Var %s\n%!" s;VAR s }
  
  | eof                                         { EOF }


