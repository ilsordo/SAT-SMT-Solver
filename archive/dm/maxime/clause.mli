type var = int

type lit = bool*var

type clause = lit list

type cnf = clause list
(* Trie et enlève les doublons des clauses *)
val make : lit list -> clause 

val merge : clause -> clause -> clause

val print_lit : out_channel -> lit -> unit 

val print_clause : out_channel -> clause -> unit

val print_cnf : out_channel -> cnf -> unit

val eval_clause : bool array -> clause -> bool





