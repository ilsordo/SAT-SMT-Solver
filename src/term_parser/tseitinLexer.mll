{
module Term_lexer = functor (Base : Term_base) -> functor (Parser : Term_parser with type atom = Base.atom) ->
struct
  
  open Parser

  type atom = Base.atom
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

  | ['a'-'z'](['0'-'9'] | ['a'-'z'])* as s 	{ ATOM (Base.parse s) }
  
  | eof                                         { EOF } 


{
 end
}
