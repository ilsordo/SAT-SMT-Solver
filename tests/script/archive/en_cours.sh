#!/bin/bash


rm -f comparaison.dat
echo "n_l_k WL DPLL" >> comparaison.dat

n=0
l=0
k=0
x=1

while read line 
do
  place=0
  for i in $line
  do
    if [[ $place -eq 0 ]]
      then 
        n=i
      else
        if [[ $place -eq 0 ]]
          then 
            l=i
          else
            if [[ $place -eq 2 ]]
              then 
                k=i
            fi
        fi
    fi
    place=$(($place + 1))
  done
  
  #WL=0
  #DPLL=0
  
  for j in {1..$x}
  do
    echo ./gen $n $l $k > /tmp/cnf-temp.txt

    echo /usr/bin/time -f'%U' -o /tmp/stat-temp.txt ./resol /tmp/cnf-temp.txt
    WL=`cat /tmp/stat-temp.txt`
    #WL=$($WL+`cat /tmp/stat-temp.txt`)   
    echo /usr/bin/time -f'%U' -o /tmp/stat-temp.txt ./resol /tmp/cnf-temp.txt
    DPLL=`cat /tmp/stat-temp.txt`
    #DPLL=$($DPLL+`cat /tmp/stat-temp.txt`)   
  done
  
  #WL=$($WL/$x)
  #DPLL=$($DPLL/$x)
  
  echo "$n_$l_$k" $WL $DPLL >> comparaison.dat 
done


