open Printf

val set_debug_level : int -> unit

val set_blocking_level : int -> unit

val set_error_channel : out_channel -> unit
 
val debug : int -> ?stops:bool -> ('a, out_channel, unit) format -> 'a





