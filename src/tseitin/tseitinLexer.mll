{
open TseitinParser;;       
}


rule token = parse
  | [' ' '\t' '\n' '\r'] 			{ token lexbuf }   
  
  | ['a'-'z'](['0'-'9'] | ['a'-'z'])* as s 	{ VAR s }
  
  | '('						{ LPAREN }  
  | ')'						{ RPAREN } 
   
  | "\\/"					{ OR }
  | '~'					  { NOT }
  | "=>"					{ IMP }
  | "<=>"				  { EQU }
  | "/\\"					{ AND }
  
  | eof           { EOF } 



