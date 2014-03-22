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
  get_timer : string -> < stop : unit >
>



