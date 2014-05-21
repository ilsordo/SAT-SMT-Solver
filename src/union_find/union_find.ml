(*****************************************************************************************************************)
(*                                                                                                               *)
(* Union-find avec backtrack et explications                                                                     *)
(*                                                                                                               *)
(* Ce module fournit une structure d'union-find de Tarjan, augmentée des deux opérations suivantes :             *)
(*   - explications(a,b) :                                                                                       *)
(*       Lorsque a et b appartiennent au même ensemble, retourne les opérations d'unions ayant conduits à cela.  *)
(*       Le nombre d'opérations retourné est minimale.                                                           *)
(*   - backtrack(a,b) :                                                                                          *)
(*       Lorsque (a,b) a été la dernière opérations d'union effectuée, l'annule.                                 *)
(*                                                                                                               *)
(* Consulter le fichier README joint pour de plus amples informations.                                           *)
(*                                                                                                               *)
(*****************************************************************************************************************)



module type Equal = sig
  type t
  val eq: t -> t -> bool
end


module Make(X: Equal) = struct

  module UF = Map.Make(struct type t = X.t let compare = compare end)
  
  module Edges = Map.Make(struct type t = X.t * X.t let compare = compare end)
      
  type t =
    { 
      next_edge : int ; (* prochain numéro d'arêtes disponibles = nombre d'union effectivement effectuées - 1 *)
      edges : (int * bool * X.t * X.t) UF.t ; (* orienté : (k,b,x,y) : la kème arête ajoutée a été provoquée par l'union de x vers y. b vraie ssi ajout a augmenté profondeur arbre *)
      edges_real : (X.t * X.t) Edges.t; (* associe à chaque edge : racine/source réels de chaque arête dans arbres *)
      depth : int UF.t ; (* profondeur de sous-arbres enracinés *)
      parents : X.t UF.t ; (* parents de chaque noeud, noeud lui-même si racine *)
      parents_compress : X.t UF.t (* parents avec compression paresseuse *)
    }
    
  
  let empty = 
    {
      next_edge = 1;
      edges = UF.empty;
      edges_real = Edges.empty;
      depth = UF.empty ;
      parents = UF.empty;
      parents_compress = UF.empty
    }
    
    
  let find a r = (* avec compression à la volée et ajout de a si non présent *)   
    let rec aux b acc = (* acc : compressions à faire quand racine trouvée *)
      let c = UF.find b r.parents_compress in
        if c = b then
          let parents_compress = (* on compresse tout ce qu'on a rencontré sur le chemin *)
            List.fold_left (fun p_compress d -> UF.add d c p_compress) r.parents_compress acc in
          (Some c,{r with parents_compress = parents_compress}) 
        else
          aux c (c::acc) (* on continue de remonter dans l'arbre *)
    in
      try
        let _ = UF.find a r.parents_compress in
        begin
          try
            aux a []
          with
            | Not_found -> assert false (* arbre sans racine contenant a ! *)
        end
      with
        | Not_found -> (* a n'est pas présent dans les ensembles, on l'ajoute *)
            (Some a,{r with depth = UF.add a 1 r.depth ; parents = UF.add a a r.parents ; parents_compress = UF.add a a r.parents_compress})
        
        
  let are_equal a b r = (* avec ajout de a et b si non présents *)
    let (a0,r0) = find a r in
    let (a1,r1) = find b r0 in (* comprimés à la volée *)  
      match (a0,a1) with
        | (Some b0,Some b1) when b0=b1 -> (true,r1)
        | _ -> (false,r1)
           
           
  let union a b r = (* avec ajout de a et b si non présents *)
    let (a0,r0) = find a r in
    let (a1,r1) = find b r0 in (* comprimés à la volée *)
      match (a0,a1) with
        | (Some b0, Some b1) when b0=b1 -> r1 (* pas d'union redondante = on a bien des arbres *)
        | (Some b0, Some b1) -> (* union équilibrée *)  
            let k0 = UF.find b0 r1.depth in
            let k1 = UF.find b1 r1.depth in
            begin
              if k0 <= k1 then
              {
                next_edge = r1.next_edge + 1;
                edges = if k0 = k1 then UF.add b0 (r1.next_edge,true,a,b) r1.edges else UF.add b0 (r1.next_edge,false,a,b) r1.edges;
                edges_real = Edges.add (a,b) (b0,b1) r1.edges_real;
                depth = if k0 = k1 then UF.add b1 (k1+1) r1.depth else r1.depth;
                parents = UF.add b0 b1 r1.parents;
                parents_compress =  UF.add b0 b1 r1.parents_compress
              }          
              else
              {
                next_edge = r1.next_edge + 1;
                edges = UF.add b1 (r1.next_edge,false,b,a) r1.edges;
                edges_real  = Edges.add (a,b) (b1,b0) r1.edges_real;
                depth = r1.depth;
                parents = UF.add b1 b0 r1.parents;
                parents_compress =  UF.add b1 b0 r1.parents_compress
              }      
           end
         | _ -> assert false
         
         
         
  let lowest_common_ancestor a b r = (* plus petit ancêtre commun à a et b, None si existe pas *)
    let rec aux a acc =  
      let c = UF.find a r.parents in
        if c = a then
          (c::acc)
        else
          aux c (a::acc) in
    let fathers_of_a = aux a [] in (* tous les ancêtres de a *)     
    let rec common b =    
      if List.mem b fathers_of_a then (***)
        Some b
      else
        begin
          let c = UF.find b r.parents in  
            if b = c && not (List.mem c fathers_of_a) then (***)
              None
            else
              common c
        end in
    try
      common b
    with
      | Not_found -> None
      
      
  let old_edge a b common r = (* plus vieille arête sur le chemin menant de a et b à common // (a,(c,d),b) avec fusion next : (a,c) (d,b) *)  
    let rec aux c old =
      try
        if c = common then 
          old 
        else
          let d = UF.find c r.parents in 
          let ((k1,_,_,_) as e) = UF.find c r.edges in
          match old with
            | None -> 
                aux d (Some e)
            | Some (k0,_,_,_) -> 
                if k1 > k0 then 
                  aux d (Some e)
                else
                  aux d old
      with 
        | Not_found -> assert false in
    match (aux a None,aux b None) with
      | (Some (k0,_,a0,a1), None) -> (a,(a0,a1),b)
      | (None, Some (k0,_,a0,a1)) -> (b,(a0,a1),a) 
      | (Some (k0,_,a0,a1), Some (k1,_,a2,a3)) when k0 > k1 -> (a,(a0,a1),b)
      | (Some (k0,_,a0,a1), Some (k1,_,a2,a3)) when k0 < k1 -> (b,(a2,a3),a)
      | _ -> assert false
      

  let explain a b r = (* les unions ayant conduites à avoir a et b dans le même ensemble *)
    let rec aux c d =
      if c = d then
        []
      else
        match lowest_common_ancestor c d r with
          | None -> raise Exit
          | Some i ->
              let (e,(f,g),h) = old_edge c d i r in
              if (f = c && g = d || f = d && g = c) then 
                [(f,g)]
              else
                (f,g)::(List.rev_append (aux e f) (aux g h)) 
              
              in
   try
     Some (aux a b)
   with
    | Exit -> None

  (* on souhaite défaire l'union de a et b, pour cela : 
      - si pas unis, on ne fait rien
      - si unis et pas les derniers à avoir été unis : on renvoie erreur
      - sinon, on fait sauter l'union, on diminue next_edge, on fait parents_compress = parents
  *)    
  let undo_last a b r = 
    let update x y =
      let ((k,height,_,_) as e) = UF.find x r.edges in
         if k <> r.next_edge -1 then (* on ne peut défaire que la dernière union *)
           assert false
         else
           { 
             next_edge = r.next_edge - 1 ; 
             edges = UF.remove x r.edges;
             edges_real = Edges.remove (a,b) r.edges_real; 
             depth = if height then UF.add y ((UF.find y r.depth)-1) r.depth else r.depth;
             parents = UF.add x x r.parents ; 
             parents_compress = UF.add x x r.parents
           } in
    try
      let (x,y) = Edges.find (a,b) r.edges_real in (* la dernière union a relié x à y dans l'arbre *)
        update x y
    with
      | Not_found ->
          try
            let (x,y) = Edges.find (b,a) r.edges_real in
              update x y
          with
            | Not_found -> r (* ce n'est pas la dernière union effective *)
  
end
