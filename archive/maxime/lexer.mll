{
open Parser
exception Error of char
}

rule head = parse
  | "p cnf"        { HEAD }
  | [' ']          { head lexbuf }
  | ['0'-'9']+ as s{ INT (int_of_string s) }
  | '\n'           { EOL }
  | 'c'            { comment_head lexbuf }
  | _ as c         { raise (Error c) }
and comment_head = parse
  | '\n'           { head lexbuf }
  | eof            { EOF } 
  | _              { comment_head lexbuf }
and token = parse
  | [' ' '\n' '\t']     { token lexbuf }
  | '-'            { NOT }
  | 'c'            { comment_token lexbuf }
  | ['1'-'9']['0'-'9']* as s{ VAR (int_of_string s) }
  | '0'            { ZERO }
  | eof            { EOF }
  | _ as c         { raise (Error c) }
and comment_token = parse
  | '\n'           { token lexbuf }
  | eof            { EOF } 
  | _              { comment_token lexbuf }



















