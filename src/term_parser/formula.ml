module type Term_base =
sig
  type atom

  val parse_atom : string -> atom option

  val print_atom : out_channel -> atom -> unit
end

module type Term_parser =
sig
  type atom

  type token =
  | ATOM of atom
  | LPAREN
  | RPAREN
  | AND
  | OR
  | IMP
  | NOT
  | EQU
  | EOF
end
