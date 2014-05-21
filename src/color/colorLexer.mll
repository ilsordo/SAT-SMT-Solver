{
  open ColorParser
}


rule token = parse
  | [' ' '\t' '\n' '\r'] 			{ token lexbuf }    
  | "c"						            { comment lexbuf }
  | "p" | "edge"				      { token lexbuf }
  | "e"                       { EDGE }
  | ['1'-'9']['0'-'9']* as s 	{ INT (int_of_string s) } 
  | eof            			      { EOF } 


and comment = parse
  | "\n"  	                  { token lexbuf }
  | _		  	                  { comment lexbuf }
