open Config_random
open Printf

let random_edges n p pp = (* génère un graphe aléatoire de n sommets, avec proba p pour chaque arête *)
  for i=1 to (n-1) do
    for j=i+1 to n do
      if Random.float 1.0 <= p then
          fprintf pp "e %d %d\n" i j
    done
 done


let gen () =
  let (n,p) = (config.param1,config.param4) in
    if (0.<=p && p<=1.) then
      printf "p edge %d %d\n%t%!" n 0 (random_edges n p) (*** il faut trouver un moyen de connaitre le nb d'aretes créées (pour l'instant j'ai mis 0) *)
    else
      eprintf "Error : p doit être une probabilité (0<=p<=1)\n%!"
(*** suite de la remarque ci-dessus : en fait, connaitre le nb d'arêtes du graphe n'est pas nécessaire dans notre algo. Donc on laisse 0 ? *)
