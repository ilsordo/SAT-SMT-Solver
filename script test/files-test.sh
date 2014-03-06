#!/bin/bash


rm -f comparaison.dat
echo "argument DPLL WL" >> comparaison.dat

declare -i compteur=0

for entree in `ls $1`; do

  compteur=compteur+1
  
  echo "exécution $compteur de DPLL sur l'entrée" $entree

  echo $entree | /usr/bin/time -f'%U' -o /tmp/stat-temp.txt ./resol $1/$entree 

  TEMPS1=`cat /tmp/stat-temp.txt`
  
  echo "exécution $compteur de WL sur l'entrée" $entree

  echo $entree | /usr/bin/time -f'%U' -o /tmp/stat-temp.txt ./resol-wl $1/$entree

  TEMPS2=`cat /tmp/stat-temp.txt`

  echo $compteur $TEMPS1  $TEMPS2 >> comparaison.dat 

  echo -e "Temps d'exécution enregistré dans comparaison.dat\n"
  
done
