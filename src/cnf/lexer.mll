{
open Parser;;        
}


rule token = parse
  | [' ' '\t' '\n' '\r']     			{ token lexbuf }    
  | "c"						            { comment lexbuf }
  | "p" | "cnf"					      { token lexbuf }
  | '-'						            { MINUS }
  | ['1'-'9']['0'-'9']* as s 	{ INT (int_of_string s) } 
  | "0"						            { ENDC }
  | eof            			      { EOF } 


and comment = parse
  | "\n"  	                  { token lexbuf }
  | _		  	                  { comment lexbuf }
