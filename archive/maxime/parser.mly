%{

open Clause;;

(*ignore (Parsing.set_trace true)*)
   
%}

%token <int> VAR INT 
%token NOT HEAD
%token EOL ZERO EOF

%start main head
%type <Clause.cnf> main
%type <int> head 

%%
head :
| HEAD INT INT EOL { $2 }
main :
| clauses        { $1 } 
;
clauses :
| clause clauses           { (make $1)::$2 }
| EOF                                     { [] }
;
clause :
| lit clause                          { $1::$2 }
| ZERO                                    { [] }
;
lit :
| VAR                                 { (true,$1) }
| NOT VAR                             { (false,$2) }






