open Printf

let _=
	let k = int_of_string Sys.argv.(1) in
		Random.self_init();
		printf "p cnf "; print_int k; printf " "; print_int (4*k); print_newline();
		for i=1 to 4*k do
			for j=1 to 3 do
				begin
					if (Random.bool())
					then (print_int ((Random.int k)+1) ; printf " ")
					else (print_int (-((Random.int k)+1)) ; printf " ")
				end
			done;
			printf "0\n"
		done
			
