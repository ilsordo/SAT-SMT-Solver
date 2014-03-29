#!/bin/bash


rm -f donnees.dat



read NB_ALGOS # nb d'algos qu'on va utiliser (1 algo = wl ou dpll + 1 heuristique)

for i in `seq 1 $NB_ALGOS` # on recupère tous les algos
do
  read ALGO HEUR
  algos[$i]=$ALGO # wl ou dpll
  heurs[$i]=$HEUR # 1 heuristique
done
  
read NB_TESTS NB_PASSAGES # nb de tests qu'on va mener / nb de fois que chaque test sera répété


# on rempli le début de donnees.dat
echo "$NB_ALGOS $NB_PASSAGES" >> donnees.dat
printf "n_l_k" >> donnees.dat
for f in `seq 1 $NB_ALGOS`
do
  printf " %s+%s" ${algos[$f]} ${heurs[$f]}  >> donnees.dat
done
printf "\n"  >> donnees.dat



for j in `seq 1 $NB_TESTS`
do
  read n l k # on récupère un test = un triplet (n,l,k)
  
  for p in `seq 1 $NB_ALGOS`
  do
    res[$p]=0 # on met les tps d'exécution pour chaque algo à 0
  done
   
  STORE=$(pwd) # on sauve le répertoire dans lequel on est
  cd ..
  cd .. # on est placé au niveau de l'exécutable resol
  for h in `seq 1 $NB_PASSAGES`
  do
    rm -f /tmp/cnf-temp.txt
    ./gen $n $l $k >> /tmp/cnf-temp.txt # on génère un test (n,l,k) aléatoire

    for m in `seq 1 $NB_ALGOS` # pour chaque algo...
    do
      echo "(test $j / $NB_TESTS) passage $h sur ($n,$l,$k) pour ${algos[$m]} avec ${heurs[$m]}"
      /usr/bin/time -f'%U' -o /tmp/stat-temp.txt ./resol -algo ${algos[$m],,} -h ${heurs[$m],,}  /tmp/cnf-temp.txt # on récupère le tps d'exécution
      TEMP=`cat /tmp/stat-temp.txt`
      res[$m]=`echo "${res[$m]} + $TEMP" | bc -l` # on l'ajoute au temps stocké pour cet algo
    done 
  done
  cd $STORE # on revient dans le répertoire du début

  # on enregistre dans donnees.dat les tps d'exécution moyen de chaque algo sur (n,l,k)
  printf "(%d,%d,%d)" $n $l $k >> donnees.dat  
  for r in `seq 1 $NB_ALGOS`
  do
    res[$r]=`echo "scale=3; ${res[$r]} / $NB_PASSAGES" | bc -l` # on divise par le nombres de passages pour avoir un temps moyen d'exécution pour chaque algo
    printf " %s" ${res[$r]} >> donnees.dat
  done
  printf "\n" >> donnees.dat
done
