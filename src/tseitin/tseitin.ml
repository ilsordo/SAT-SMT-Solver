type tseitin_formule =
  | Var of string
  | And of tseitin_formule*tseitin_formule (* et *)
  | Or of tseitin_formule*tseitin_formule  (* ou *)
  | Imp of tseitin_formule*tseitin_formule (* implication *)
  | Equ of tseitin_formule*tseitin_formule (* on gère même l'équivalence ! *)
  | Not of tseitin_formule                 (* négation *)


let to_cnf t_formule = (* construit la cnf, en utilisant des variables fraiches *)
  let rec aux t_f = match t_f with
    | Var v -> ((true,v),[])
    | Not f -> let ((b,v),g)=aux f in
                ((not b,v),g)
    | And(f,g) -> let ((b1,v1),h1)=aux f in
                  let ((b2,v2),h2)=aux g in
                  let fresh="_"^(mfresh()) in
                    ((true,fresh),List.rev_append h1 (List.rev_append h2 [[(not b1,v1);(not b2,v2);(true,fresh)];[(false,fresh);(b1,v1)];[(false,fresh);(b2,v2)]])) 
    | Or(f,g) -> let ((b1,v1),h1)=aux f in
                 let ((b2,v2),h2)=aux g in
                 let fresh="_"^mfresh() in
                   ((true,fresh),List.rev_append h1 (List.rev_append h2 [[(not b1,v1);(true,fresh)];[(not b2,v2);(true,fresh)];[(false,fresh);(b1,v1);(b2,v2)]])) 
    | Imp(f,g) -> let ((b1,v1),h1)=aux f in
                  let ((b2,v2),h2)=aux g in
                  let fresh="_"^mfresh() in
                    ((true,fresh),List.rev_append h1 (List.rev_append h2 [[(b1,v1);(true,fresh)];[(not b2,v2);(true,fresh)];[(false,fresh);(not b1,v1);(b2,v2)]]))
    | Equ(f,g) -> aux (And(Imp(f,g),Imp(g,f)))
  in let (p,f)=aux t_formule in
    ([p]::f)
      
let parse input =
  try
    let lex = Lexing.from_channel input in
    TseitinParser.main TseitinLexer.token lexbuf
  with
    | _ -> 
        eprintf "Input error\n%!";
        exit 1
