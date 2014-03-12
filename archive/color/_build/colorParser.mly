

%token <int> INT 
%token EDGE EOF



%start main             	
%type <(int*int*((int*int) list))> main

%%


main:                      
| color_formule EOF                 { $1 }
  ;

  color_formule:														
| INT INT edges       	      { ($1,$2,$3) }
  ;
  
  edges:
| EDGE INT INT edges          { ($2,$3)::$4}
|                             { [] }


