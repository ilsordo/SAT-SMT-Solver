open Clause
open Formule

type wl_update = WL_Conflit | WL_New of literal | WL_Assign of literal | WL_Nothing

class formule_wl :
object

  inherit formule
  
  method get_wl : literal -> clauseset
  method watch : clause -> literal -> literal -> unit
  method init_wl : unit
  method set_wl : literal -> literal -> clause -> unit 
  method update_clause : clause -> literal -> wl_update 
  
end










