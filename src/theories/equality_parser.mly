%{
  open Formula_tree
  
  let make_atom s1 s2 =
    if s1 < s2 then
      Atom (s1,s2)
    else
      Atom (s2,s1)
%}

%token <string> VAR
%token LPAREN RPAREN
%token AND OR IMP NOT EQU
%token EQ NEQ
%token EOF

%nonassoc EQU
%right IMP
%left OR
%left AND
%nonassoc NOT


%start main             	
%type <(string*string) Formula_tree.formula_tree> main

%%


main:                      
| formule EOF                             { $1 }
  ;

  formule:	
| LPAREN formule RPAREN                   { $2 }
| VAR EQ VAR                              { make_atom $1 $3 }
| VAR NEQ VAR                             { Not (make_atom $1 $3) }
| formule AND formule                     { And($1,$3) }
| formule OR formule                      { Or($1,$3) }
| formule IMP formule                     { Imp($1,$3) }
| formule EQU formule                     { Equ($1,$3) }
| NOT formule                             { Not($2) }
  ;
  













