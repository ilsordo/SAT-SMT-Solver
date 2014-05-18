
module type Equal = sig
  type t 
  val eq: t -> t -> bool
end

module Make(X: Equal): sig

  type t

  val empty: t  
  
  val union: X.t -> X.t -> t -> t
  
  val find : X.t -> t -> X.t option * t 
  
  val are_equal: X.t -> X.t -> t -> bool * t
  
  val explain: X.t -> X.t -> t -> (X.t * X.t) list option
  
  val undo_last : X.t -> X.t -> t -> t

end
