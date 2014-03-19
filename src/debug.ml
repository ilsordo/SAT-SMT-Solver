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

class stat init =
object
  val data : (string,int) Hashtbl.t = Hashtbl.create 10
  
  initializer
    List.iter (fun s -> Hashtbl.add data s 0) init
    
  method record s = 
    try 
      let n = Hashtbl.find data s in
      Hashtbl.replace data s (n+1)
    with
      | Not_found -> 
          Hashtbl.add data s 1
          
  method get s = 
    try Hashtbl.find data s with Not_found -> 0

  method print p =
    Hashtbl.iter (fun s n -> fprintf p "[stats] %s = %d\n" s n) data
end
  
let stats = new stat ["Conflits";"Paris"] (* Pour afficher Conflits = 0 *)
  
let record_stat s = stats#record s

let get_stat s = stats#get s

let print_stats p = stats#print p

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












