{
  open Formula_tree

  module Make_lexer = functor (Base : Term_base) -> functor (Parser : Term_parser with type atom = Base.atom) ->
  struct
  
  open Parser

  type atom = Base.atom
}

let atom_sym = ['a'-'z' 'A'-'Z' '0'-'9' ' ' '(' ')' ',' '=' '<' '>' '-'] | "<=" | ">=" | "!="

rule token = parse
  | [' ' '\t' '\n' '\r'] 			{ token lexbuf }   

  | '('						{ LPAREN }  
  | ')'						{ RPAREN } 
   
  | "\\/"					{ OR }
  | '~'					        { NOT }
  | "=>"					{ IMP }
  | "<=>"				        { EQU }
  | "/\\"					{ AND }

  | ['a'-'z'] atom_sym* as s 	{ ATOM (Base.parse_atom s) }
  
  | eof                                         { EOF } 


{
 end
}
