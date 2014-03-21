#!/bin/bash


rm -f donnes.dat

x=2 # nb de repetition de chaque test

#echo "Temps d'exécution des algorithmes ($x passages)" >> donnees.dat 
echo "n_l_k WL DPLL" >> donnees.dat

while read line
do
  for i in $line
  do
    if [[ $place -eq 0 ]]
      then 
        n=$i
        place=1
      else
        if [[ $place -eq 1 ]]
          then 
            l=$i
            place=2
          else
            if [[ $place -eq 2 ]]
              then 
                k=$i
                place=0
            fi
        fi
    fi
  done
  
  WL=0
  DPLL=0
   
  STORE=$(pwd)
  cd ..
  cd ..
  for j in `seq 1 $x`
  do
    rm -f /tmp/cnf-temp.txt
    ./gen $n $l $k >> /tmp/cnf-temp.txt

    echo "passage $j sur ($n,$l,$k) pour WL"
    /usr/bin/time -f'%U' -o /tmp/stat-temp.txt ./resol /tmp/cnf-temp.txt
    TEMP=`cat /tmp/stat-temp.txt`
    WL=`echo "$WL + $TEMP" | bc -l`
 
    echo "passage $j sur ($n,$l,$k) pour DPLL"   
    /usr/bin/time -f'%U' -o /tmp/stat-temp.txt ./resol-wl /tmp/cnf-temp.txt 
    TEMP=`cat /tmp/stat-temp.txt`
    DPLL=`echo "$DPLL + $TEMP" | bc -l`
  done
  cd $STORE
  
  WL=`echo "$WL / $x" | bc -l`
  DPLL=`echo "$DPLL / $x" | bc -l`
  
  echo "($n,$l,$k)" $WL $DPLL >> donnees.dat 
done

