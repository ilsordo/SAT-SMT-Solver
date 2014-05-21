%{
  open Formula_tree

  type base = string*string*int  

  type rel =
    | Leq of base
    | Geq of base
    | Lt of base
    | Gt of base
    | Eq of base

(** Normalisation *)

let rec normalize = function
  | Leq (s1,s2,n) when s1 < s2 -> Atom (s1,s2,n)
  | Leq (s1,s2,n) -> Not (Atom (s2,s1,-n-1))
  | Geq (s1,s2,n) -> normalize (Leq (s2,s1,-n))
  | Lt (s1,s2,n) -> normalize (Leq (s1,s2,n-1))
  | Gt (s1,s2,n) -> normalize (Leq (s2,s1,-n-1))
  | Eq (s1,s2,n) -> And (normalize (Leq (s1,s2,n)), normalize (Leq (s2,s1,-n)))

%}

%token <string> VAR
%token <int> INT
%token LPAREN RPAREN
%token AND OR IMP NOT EQU
%token DIFF
%token EQ NEQ LEQ GEQ LT GT
%token EOF

%nonassoc EQU
%right IMP
%left OR
%left AND
%nonassoc NOT

%nonassoc UMINUS

%start main             	
%type <(string*string*int) Formula_tree.formula_tree> main

%%


main:                      
| formule EOF                             { $1 }
  ;

  formule:	
| LPAREN formule RPAREN                   { $2 }
| atom                                    { $1 }
| formule AND formule                     { And($1,$3) }	
| formule OR formule                      { Or($1,$3) }													
| formule IMP formule                     { Imp($1,$3) }
| formule EQU formule                     { Equ($1,$3) }
| NOT formule                             { Not($2) }			
  ;
  
int :
| INT                        { $1 }
| DIFF INT %prec UMINUS      { - $2 }
;
atom:
| VAR LEQ int     { normalize (Leq($1,"_phantom",$3)) }
| VAR GEQ int     { normalize (Geq($1,"_phantom",$3)) }
| VAR LT int      { normalize (Lt($1,"_phantom",$3)) }
| VAR GT int      { normalize (Gt($1,"_phantom",$3)) }
| VAR EQ int      { normalize (Eq($1,"_phantom",$3)) }
| VAR NEQ int     { Not (normalize (Eq($1,"_phantom",$3))) }

| VAR DIFF VAR LEQ int     { normalize (Leq($1,$3,$5)) }
| VAR DIFF VAR GEQ int     { normalize (Geq($1,$3,$5)) }
| VAR DIFF VAR LT int      { normalize (Lt($1,$3,$5)) }
| VAR DIFF VAR GT int      { normalize (Gt($1,$3,$5)) }
| VAR DIFF VAR EQ int      { normalize (Eq($1,$3,$5)) }
| VAR DIFF VAR NEQ int     { Not (normalize (Eq($1,$3,$5))) }


