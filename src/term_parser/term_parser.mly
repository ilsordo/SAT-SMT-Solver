
%parameter<Base : Formula_tree.Term_base>

%{
  open Formula_tree
%}

%token <string> ATOM
%token LPAREN RPAREN
%token AND OR IMP NOT EQU
%token EOF

%nonassoc EQU
%right IMP
%left OR
%left AND
%nonassoc NOT


%start main             	
%type <Base.atom Formula_tree.formula_tree> main

%%


main:                      
| formule EOF                             { $1 }
  ;

  formule:	
| LPAREN formule RPAREN                   { $2 }
| ATOM                                    { Base.parse_atom $1 }
| formule AND formule                     { And($1,$3) }	
| formule OR formule                      { Or($1,$3) }													
| formule IMP formule                     { Imp($1,$3) }
| formule EQU formule                     { Equ($1,$3) }
| NOT formule                             { Not($2) }			
  ;
  













