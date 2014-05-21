%{
  open Formula_tree
  open Congruence_type
%}

%token <string> FUN VAR
%token LPAREN RPAREN
%token AND OR IMP NOT EQU
%token EQ NEQ
%token SEP
%token EOF

%nonassoc EQU
%right IMP
%left OR
%left AND
%nonassoc NOT

%start main             	
%type <(Congruence_type.t*Congruence_type.t) Formula_tree.formula_tree> main

%%


main:                      
| formule EOF                             { $1 }
  ;

  formule:	
| LPAREN formule RPAREN                   { $2 }
| term EQ term                            { Atom ($1,$3) }
| term NEQ term                           { Not (Atom ($1,$3)) }
| formule AND formule                     { And($1,$3) }	
| formule OR formule                      { Or($1,$3) }													
| formule IMP formule                     { Imp($1,$3) }
| formule EQU formule                     { Equ($1,$3) }
| NOT formule                             { Not($2) }			
  ;
  
  term:
| VAR                                     { Var $1 }
| FUN arg_list RPAREN                     { Fun ($1,$2) }
| FUN RPAREN                              { Fun($1,[]) }
;
  arg_list:
| term SEP arg_list                       { $1::$3 }
| term                                    { [$1] }



















