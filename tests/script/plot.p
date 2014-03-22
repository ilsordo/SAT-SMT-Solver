
reset

### pour pdf
# set term pdfcairo
# set output "courbe1.pdf" # le nom du fichier qui est engendre


stats 'donnees.dat' every ::::0 using 1 nooutput
NB_ALGOS = int(STATS_min)
stats 'donnees.dat' every ::::0 using 2 nooutput
NB_PASSAGES = int(STATS_min)

set title sprintf('Temps d''exécution des algorithmes (%d passages)', NB_PASSAGES)
set xlabel "Tests (n,l,k)"
set ylabel "Temps exécution (s)"



set style data linespoints

set pointsize 1   


# on trace deux courbes: avec les colonnes 1 et 2, avec les colonnes 1 et 3
# a chaque fois, le nom de la courbe est lu en tete de colonne

#plot "donnees.dat" every ::1 using 2:xticlabels(1) title columnheader(2), \
#     "donnees.dat" every ::1 using 3:xticlabels(1) title columnheader(3)


plot for [i=2:(3+1)] "<(sed '1d' donnees.dat)"  using i:xticlabels(1) title columnheader(i)
