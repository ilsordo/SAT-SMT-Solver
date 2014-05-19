open Printf

let random_edges n p out_c = (* génère un graphe aléatoire de n sommets, avec proba p pour chaque arête *)
  for i=1 to (n-1) do
    for j=i+1 to n do
      if Random.float 1.0 <= p then
          fprintf out_c "e %d %d\n" i j
    done
 done


let gen n p=
  if (0.<=p && p<=1.) then
    printf "p edge %d %d\n%t%!" n 1 (random_edges n p) (*on indique 1 arête car on ne peux pas savoir à priori combien il y en aura. Nos algorithmes n'ont pas besoin de ce nombre*)
  else
    eprintf "Error : p doit être une probabilité (0<=p<=1)\n%!"
