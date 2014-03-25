open Printf

let random_connecteur = function 
    | 0 -> "~"
    | 1 -> "\\/" 
    | 2 -> "/\\"
    | 3 -> "=>"        
    | 4 -> "<=>"  
    | _ -> assert false      
    
    
let rec random_formula n c p = (* génère une formule aléatoire de c connecteurs et n variables *)
  if c=0 then
    fprintf p "a%d" (Random.int n)
  else
    match random_connecteur (Random.int 5) with
      | "~" -> 
          fprintf p "~(%t)" (random_formula n (c-1))
      | s ->
          fprintf p "(%t)%s(%t)" (random_formula n ((c-1)/2)) s (random_formula n (c-1-(c-1)/2))


let gen n c = 
  if (c>0 && n>0) then
    printf "%t\n%!" (random_formula n c) 
  else
    eprintf "Error : n et c doivent être supérieurs à 0\n%!"

