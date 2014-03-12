{
open TseitinParser;;        
}


rule token = parse
  | [' ' '\t' '\n']     			              { token lexbuf }   
  
  | ['a'-'z'](['1'-'9'] | ['a'-'z'])* as s 	{ VAR s }
  
  | '('						                          { LPAREN }  
  | ')'						                          { RPAREN } 
   
  | "\\/"						                        { OR }
  | '~'						                          { NOT }
  | "=>"						                        { IMP }
  | "<=>"						                        { EQU }
  | "/\\"						                        { AND }
  
  | eof            			                    { EOF } 



