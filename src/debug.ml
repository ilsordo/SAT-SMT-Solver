open Printf

let rec indent p k =
  if k>0 then
    fprintf p " %a" indent (k-1)

let debug =
object
  val mutable debug_level = 0
  val mutable blocking_level = 0
  val mutable error_channel = stderr
    
  method set_debug_level x = 
    assert (x>=0); 
    debug_level <- x

  method set_blocking_level x =
    assert (x>=0); 
    blocking_level <- x

  method set_error_channel c =
    error_channel <- c

(* Plus les messages expriment une info détaillée, plus le niveau est haut *)
(* Usage : remplacer eprintf format arg1 ... argN par debug#p k format arg1 ... argN *)
  method p : 'a.int -> ?stops:bool -> ('a, out_channel, unit) format -> 'a =
    fun k ?(stops=false) ->
    assert (k>=0);
    if debug_level >= k then
      begin
        fprintf (error_channel) "[debug]%a" indent k;
        kfprintf (fun p -> 
          fprintf p "\n%!";
          if stops && blocking_level >= k then
            begin
              fprintf (error_channel) ">%!";
              ignore (input_line stdin)
            end)
          (error_channel)
      end
    else
      ifprintf stdout (* Ne fait rien *)
end



let stats =
  let init = ["Conflits";"Paris"] in
object
  val data : (string,int) Hashtbl.t = Hashtbl.create 10
  val mutable timers : (string*float) list = []

  initializer
    List.iter (fun s -> Hashtbl.add data s 0) init
    
  method record s = 
    try 
      let n = Hashtbl.find data s in
      Hashtbl.replace data s (n+1)
    with
      | Not_found -> 
          Hashtbl.add data s 1

  method print p =
    Hashtbl.iter (fun s n -> fprintf p "[stats] %s = %d\n" s n) data;
    fprintf p "\n";
    List.iter (fun (s,t) -> fprintf p "[timer] %s : %.5f s\n" s t) timers

  method get_timer s = 
    let start = Unix.times() in 
  object 
    val mutable dead = false
      
    method stop =
      let stop = Unix.times() in
      timers <- Unix.(s, stop.tms_utime +. stop.tms_stime -. (start.tms_utime +. start.tms_stime))::timers;
      assert (not dead);
      ignore (dead = true)
  end
end



















