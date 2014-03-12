open Tseitin

let lexbuf = Lexing.from_channel stdin


let parse () = TseitinParser.main TseitinLexer.token lexbuf



let tseitin_to_formule () =
  let result = parse () in
  let (tf,f,assoc)=tseitin result in
  
    print_string "p cnf ";
    print_int (Association.cardinal assoc);
    print_string " ";
    print_int (List.length tf);
    print_newline();
    
		List.iter 
		  (fun c -> List.iter 
		              (fun lit -> print_int lit ; print_string " ")
		              c ; print_int 0 ; print_newline()) 
		  f;
		print_newline();
		
		print_string "Association : \n";
	  Association.iter (fun s s_new -> print_string s ; print_string "  " ; print_int s_new ; print_newline ()) assoc;
		flush stdout


let _ = tseitin_to_formule()
