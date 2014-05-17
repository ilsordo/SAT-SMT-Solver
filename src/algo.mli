open Algo_base

type t = Heuristic.t -> bool -> bool -> int -> int list list -> Answer.t

module Bind : functor (Base : Algo_base) -> 
sig
  val algo : t 
end











