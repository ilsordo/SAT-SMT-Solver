

%token <int> INT 
%token MINUS ENDC EOF



%start main             	
%type <int*((int list) list)> main



%%



main:                      
formule EOF                 { $1 }			
  ;

  formule:														
  | INT INT liste_clause				{ ($1,_,$3) }
  ;

  liste_clause:
  | clause ENDC liste_clause		{ $1::$3}
  | clause ENDC									{ [$1] }
  | clause											{ [$1] }
  ;

  clause:
  | MINUS INT clause 						{ (-$2)::$3 }
  | INT clause 									{ $1::$2 }
  | MINUS INT 									{ [-$2] }
  | INT													{ [$1] }
  ;
