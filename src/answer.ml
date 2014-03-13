open Formule

type answer = Unsolvable | Solvable of bool vartable

type problem = Cnf | Color of int | Tseitin



let print_valeur p v = function (* affichage d'une variable (int) et de sa valeur *)
  | true -> Printf.fprintf p "v %d\n" v
  | false -> Printf.fprintf p "v -%d\n" v

let print_valeur_s p s = function (* affichage d'une variable (string) et de sa valeur *)
  | None -> assert false
  | Some true -> Printf.fprintf p "v %s\n" s
  | Some false -> Printf.fprintf p "v -%s\n" s
  
let print_sommet p s = (* pour le coloriage. s=i_k où i : sommet considéré, k : couleur de i *)
  let l=String.length s in
  let cut = String.index s '_' in
  Printf.fprintf p "%s colorié en %s\n" (String.sub s 0 cut) (String.sub s (cut+1) (l-cut-1))

  

let print_answer p (answer,assoc,pb_type) = match answer with
  | Unsolvable -> Printf.fprintf p "s UNSATISFIABLE\n"
  | Solvable valeurs -> 
      Printf.fprintf p "s SATISFIABLE\n";
      match pb_type with
        | Tseitin ->
            begin
              match assoc with
                | None -> assert false
                | Some asso -> asso#iter (fun s v -> if (s.[0] <>'_') then print_valeur_s p s (valeurs#find v) else ())
            end
        | Color k -> 
            begin
              match assoc with
                | None -> assert false
                | Some asso -> asso#iter (fun s v -> if ((valeurs#find v)=(Some true)) then 
                                                        print_sommet p s
                                                     else ())
            end
        | Cnf -> 
            for v=1 to valeurs#size do
            match valeurs#find v with
              | None -> assert false
              | Some b -> print_valeur p v b
            done 
                                     
