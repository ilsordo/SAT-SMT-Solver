%{
open Tseitin
%}

%token <string> VAR 
%token LPAREN RPAREN
%token AND OR IMP NOT EQU
%token EOF

%left AND
%left OR
%left EQU
%left IMP 

%right NOT /* pas nécessaire ? */

%start main             	
%type <Tseitin.tseitin_formule> main

%%


main:                      
| tseitin_formule EOF                     { $1 }
  ;

  tseitin_formule:	
| LPAREN tseitin_formule RPAREN           { $2 }
| VAR                                     { Var($1) }
| tseitin_formule AND tseitin_formule     { And($1,$3) }	
| tseitin_formule OR tseitin_formule      { Or($1,$3) }													
| tseitin_formule IMP tseitin_formule     { Imp($1,$3) }
| tseitin_formule EQU tseitin_formule     { Equ($1,$3) }
| NOT tseitin_formule                     { Not($2) }			
  ;
  


