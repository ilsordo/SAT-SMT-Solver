
module type Equal = sig
  type t 
  val eq : t -> t -> bool
  val print : out_channel -> t -> unit
end

module Make(X: Equal): sig
  
  type t
  
  exception Neg_cycle of X.t * t 
  
  val empty : t
  
  val add_node : X.t -> t -> t
  
  val add_edge : X.t -> X.t -> int -> t -> t
  
  val remove_edge : X.t -> X.t -> int -> t -> t
  
  val relax_edge : X.t -> X.t -> int -> t -> t 
  
  val neg_cycle : X.t -> t -> (int * X.t * X.t) list
  
  val print_values : out_channel -> t -> unit
  
end
