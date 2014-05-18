


module type Equal = sig
  type t
  val eq: t -> t -> bool
  val print: t -> unit
end


module Make(X: Equal) = struct

  module UF = Map.Make(struct type t = X.t let compare = compare end)
    
  type t =
    { 
      next_edge : int ;
      edges : (int * bool * X.t * X.t) UF.t ; (* true si sens ok *)
      depth : int UF.t ;
      parents : X.t UF.t ;
      parents_compress : X.t UF.t 
    }
    
  
  let empty = 
    {
      next_edge = 1;
      edges = UF.empty;
      depth = UF.empty ;
      parents = UF.empty;
      parents_compress = UF.empty
    }
    
  (* r : la structure d'uf*)
    
  let find a r = (* ici : compression à la volée *)   
    let rec aux b acc = (* acc : compression à faire quand racine trouvée *)
      let c = UF.find b r.parents_compress in
      if c = b then
        let parents_compress = 
          List.fold_left (fun p_compress d -> UF.add d c p_compress) r.parents_compress acc in
        (c,{r with parents_compress = parents_compress}) 
      else
        aux c (c::acc)
    in
    try
      aux a []
    with (* seul a devrait être not found *)
      | Not_found -> (a,{r with depth = UF.add a 1 r.depth ; parents = UF.add a a r.parents ; parents_compress = UF.add a a r.parents_compress})
        
  let are_equal a b r =
    let (a0,r0) = find a r in
    let (a1,r1) = find b r0 in (* comprimé à la volée *)  
    (a0 = a1,r1)  
           
  let union a b r = 
    let (a0,r0) = find a r in
    let (a1,r1) = find b r0 in (* comprimé à la volée *)
    if a0 = a1 then
      r1
    else (* union équilibrée *)
      let k0 = UF.find a0 r1.depth in
      let k1 = UF.find a1 r1.depth in
      if k0 = k1 then
        {
          next_edge = r1.next_edge + 1;
          edges = UF.add a0 (r1.next_edge,true,a,b) r1.edges;
          depth = UF.add a1 (k1+1) r1.depth;
          parents = UF.add a0 a1 r1.parents;
          parents_compress =  UF.add a0 a1 r1.parents_compress
        }          
      else if k0 < k1 then
        {
          next_edge = r1.next_edge + 1;
          edges = UF.add a0 (r1.next_edge,true,a,b) r1.edges;
          depth = r1.depth;
          parents = UF.add a0 a1 r1.parents;
          parents_compress =  UF.add a0 a1 r1.parents_compress
        }
      else
        {
          next_edge = r1.next_edge + 1;
          edges = UF.add a1 (r1.next_edge,false,a,b) r1.edges;
          depth = r1.depth;
          parents = UF.add a1 a0 r1.parents;
          parents_compress =  UF.add a1 a0 r1.parents_compress
        }      
  
  let lowest_common_ancestor a b r = 
    let rec aux a acc =  
      let c = UF.find a r.parents in
      if c = a then
        (c::acc)
      else
        aux c (a::acc) in
    let fathers_of_a = aux a [] in      
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
      
  let old_edge a b common r = (* (a,(c,d),b) avec fusion next : (a,c) (d,b) *)  
    let rec aux c old =
      try
        if c = common then 
          old 
        else (***)
          let d = UF.find c r.parents in 
          let ((k1,_,_,_) as e) = UF.find c r.edges in (* peut déclencher not_found ? *)
          match old with
            | None -> 
                aux d (Some e)
            | Some (k0,_,_,_) -> 
                if k1 > k0 then 
                  aux d (Some e)
                else
                  aux d old
      with 
        | Not_found -> None in
    match (aux a None,aux b None) with
      | (Some (k0,ori,a0,a1), None) -> if ori then (a,(a0,a1),b) else (b,(a0,a1),a)
      | (None, Some (k0,ori,a0,a1)) -> if ori then (b,(a0,a1),a) else (a,(a0,a1),b) 
      | (Some (k0,ori0,a0,a1), Some (k1,ori1,a2,a3)) when k0 > k1 -> if ori0 then (a,(a0,a1),b) else (b,(a0,a1),a)
      | (Some (k0,ori0,a0,a1), Some (k1,ori1,a2,a3)) when k0 < k1 -> if ori1 then (b,(a2,a3),a) else (a,(a2,a3),b)
      | _ -> assert false
      

  let explain a b r = (* construire jusqu'à reboucler sur même aretes *)
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
          

          
end
