module type Smt_base =
sig
    type atom

  val parse_atom : string -> atom option

  val print_atom : out_channel -> atom -> unit


  val 
