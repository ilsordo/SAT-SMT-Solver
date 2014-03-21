# pour visualiser le dessin trace par ce script gnuplot, taper
# gnuplot -persist script-plot.p
#  (en s`assurant que le fichier comparaison.dat est present dans le repertoire)

reset

### decommenter les 2 lignes ci-dessous pour engendrer un fichier pdf
### plutot qu`un dessin a l`ecran
# set term pdfcairo
# set output "courbe1.pdf" # le nom du fichier qui est engendre

set title "Temps d exécution des algorithmes (30 passages)"
set xlabel "Tests (n,l,k)"
set ylabel "Temps exécution (s)"


# Dessin en joignant des points
set style data linespoints

set pointsize 1   # la taille des points


# on trace deux courbes: avec les colonnes 1 et 2, avec les colonnes 1 et 3
# a chaque fois, le nom de la courbe est lu en tete de colonne
plot "donnees.dat" using 2:xticlabels(1) title columnheader(2), \
     "donnees.dat" using 3:xticlabels(1) title columnheader(3)

