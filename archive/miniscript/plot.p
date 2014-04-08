
reset

### pour pdf
 set term pdfcairo
 set output "courbe1.pdf" # le nom du fichier qui est engendre


stats 'donnees.dat' every ::::0 using 1 nooutput
NB_ALGOS = int(STATS_min)
stats 'donnees.dat' every ::::0 using 2 nooutput
NB_PASSAGES = int(STATS_min)

set title sprintf('Temps d''exécution des algorithmes (%d passages)', NB_PASSAGES)
set xlabel "Tests (n,l,k)"
set ylabel "Temps exécution (s)"


#set autoscale x

set style data linespoints

set pointsize 1   


plot for [i=2:(NB_ALGOS+1)] "<(sed '1d' donnees.dat)"  using i:xticlabels(1) title columnheader(i)
