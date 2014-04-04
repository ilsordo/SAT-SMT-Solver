open Printf

val debug : 
<
  set_debug_level : int -> unit;
  set_blocking_level : int -> unit;
  set_error_channel : out_channel -> unit;
  p : 'a.int -> ?stops:bool -> ('a, out_channel, unit) format -> 'a
>


val stats :
< 
  record : string -> unit;
  print : out_channel -> unit;
  record_timer : string -> float -> unit; 
  start_timer : string -> unit;  
  stop_timer : string -> unit
>



