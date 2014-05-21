%{
  open Formula_tree


(** Normalisation *)

let rec normalize formula = 
  let rec normalize_atom = function
    | Double (s1,s2,o,n) ->
        begin
          match o with
            | Great -> normalize (Atom (Double(s2,s1,Leq,-n-1))) 
            | Less -> normalize (Atom (Double(s1,s2,Leq,n-1))) 
            | LEq -> if s2 > s1 then Not (Atom (Double(s2,s1,Leq,n-1))) else Atom (Double(s1,s2,Leq,n))
            | GEq -> normalize (Atom (Double(s2,s1,Leq,-n)))  
            | Eq -> And(normalize (Atom (Double(s1,s2,Leq,n))),normalize (Atom (Double(s2,s1,Leq,-n))))
            | Ineq -> Not(normalize (Atom (Double(s1,s2,Eq,n))))
        end
    | Single(s,o,n) -> normalize (Atom (Double(s1,"_zero",o,n))) in (** bien gérer ce _zero après, ne pas l'afficher... *)
  match formula with
    | And (f1,f2) -> And (normalize f1,normalize f2)
    | Or (f1,f2) -> Or (normalize f1,normalize f2)
    | Imp (f1,f2) -> Imp (normalize f1,normalize f2)
    | Equ (f1,f2) -> Equ (normalize f1,normalize f2)
    | Not f -> Not (normalize f)
    | Atom a -> normalize_atom a
*)  

%}

%token <string> VAR
%token <int> INT
%token LPAREN RPAREN
%token AND OR IMP NOT EQU
%token EQ NEQ LEQ GEQ LT GT
%token EOF

%nonassoc EQU
%right IMP
%left OR
%left AND
%nonassoc NOT

%start main             	
%type <string Formula_tree.formula_tree> main

%%


main:                      
| formule EOF                             { $1 }
  ;

  formule:	
| LPAREN formule RPAREN                   { $2 }
| ATOM                                    { Atom $1 }
| formule AND formule                     { And($1,$3) }	
| formule OR formule                      { Or($1,$3) }													
| formule IMP formule                     { Imp($1,$3) }
| formule EQU formule                     { Equ($1,$3) }
| NOT formule                             { Not($2) }			
  ;
  













