open Printf

let debug_level = ref 0

let set_debug_level x = 
  assert (x>=0); 
  debug_level := x

let blocking_level = ref 0

let set_blocking_level x = 
  assert (x>=0); 
  blocking_level := x

let error_channel = ref stderr

let set_error_channel c = 
  error_channel := c

(* Plus les messages expriment une info détaillée, plus le niveau est haut *)

let rec indent p k =
  if k>0 then
    fprintf p " %a" indent (k-1)
 
(* Usage : remplacer eprintf format arg1 ... argN par debug k format arg1 ... argN *)

let debug k ?(stops=false) =
  assert (k>0);
  if !debug_level >= k then
    begin
      fprintf (!error_channel) "[debug]%a" indent k;
      kfprintf (fun p -> 
        fprintf p "\n%!";
        if stops && !blocking_level >= k then
          begin
          fprintf (!error_channel) ">%!";
            ignore (input_line stdin)
          end)
        (!error_channel)
    end
  else
    ifprintf stdout (* Ne fait rien *)












