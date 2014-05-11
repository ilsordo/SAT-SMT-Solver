%{
open Formula
%}

%token <string> VAR 
%token LPAREN RPAREN
%token AND OR IMP NOT EQU
%token EOF

%nonassoc EQU
%right IMP
%left OR
%left AND
%nonassoc NOT


%start main             	
%type <TseitinFormule.t> main

%%


main:                      
| formule EOF                             { $1 }
  ;

  formule:	
| LPAREN formule RPAREN                   { $2 }
| VAR                                     { Atom($1) }
| formule AND formule                     { And($1,$3) }	
| formule OR formule                      { Or($1,$3) }													
| formule IMP formule                     { Imp($1,$3) }
| formule EQU formule                     { Equ($1,$3) }
| NOT formule                             { Not($2) }			
  ;
  


