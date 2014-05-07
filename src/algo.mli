open Algo_base

type param = Heuristic.t -> bool -> bool -> int -> int list list

type t = 

module Bind : functor (Base : Algo_base) -> 
sig
  val algo : param -> t 
end











