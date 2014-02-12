open Printf
open Seaux
open Formule


(**************************************)
(*  Fonction d'affichage de la sortie *)
(**************************************)

let print_affectation f=	(* affiche l'affectation courante contenue dans la formule f*)
	printf "s SATISFIABLE\n";
	let k=f#get_nb_var in
	for i=1 to k do
		printf "v ";
		if (f#get_val i)=1
		then print_int i
		else print_int (-i);
		print_newline()
	done

(*******************************************)
(*  Fonctions permettant de transformer le *)
(*  résultat du parser en une formule      *)
(*******************************************)

let rec list_to_clause l c f=match l with (*ajoute à la clause c les variable de la formule f dont les noms (=int) figurent dans la liste l*)
	| [] -> ()
	| t::q -> if t>0 then ((c#add_vpos (f#get_var t)) ; list_to_clause q c f)
					 else ((c#add_vneg (f#get_var (-t)));list_to_clause q c f)

let rec listlist_to_clause l f=match l with (* ajoute à la formule f les clauses construites à partir de la liste de clauses l (l est de type (int list) list) *)
	| [] -> ()
	| t::q -> (let c=new clause in (f#add_clau c ; list_to_clause t c f)) ; listlist_to_clause q f


(*******************************************************)
(* Application des algorithmes, production du résultat *)
(*******************************************************)

let clauses_file = open_in Sys.argv.(1)
let lexbuf = Lexing.from_channel clauses_file
let parse () = Parser.main Lexer.token lexbuf


let _ =
      let (a,b,l) = parse () in (* a = nb de variables, b = nb de clauses, l (de type (int list) list) = les clauses *)
		let f = new formule a in 
			for i=1 to a do
				f#add_var (new variable i) i (* on ajoute a variables à f*)
			done;
			listlist_to_clause l f ; (* on ajoute les clauses à f*)
			try 
				affecter f;  (* une affectation des variables est construite *)
				print_affectation f  
			with 
				| Failure "unsatis" -> printf "s UNSATISFIABLE\n"; (*aucune affectation ne met la formule à vraie *)
		print_newline();
		flush stdout






