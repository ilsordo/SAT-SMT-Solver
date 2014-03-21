# pour visualiser le dessin trace par ce script gnuplot, taper
# gnuplot -persist script-plot.p
#  (en s`assurant que le fichier comparaison.dat est present dans le repertoire)

reset

### decommenter les 2 lignes ci-dessous pour engendrer un fichier pdf
### plutot qu`un dessin a l`ecran
# set term pdfcairo
# set output "courbe1.pdf" # le nom du fichier qui est engendre

set title "DPLL et WL"
set xlabel "Tests"
set ylabel "Temps execution"


# Dessin en joignant des points
set style data linespoints

set pointsize 2   # la taille des points


# on trace deux courbes: avec les colonnes 1 et 2, avec les colonnes 1 et 3
# a chaque fois, le nom de la courbe est lu en tete de colonne
plot "comparaison.dat" using 1:2 title columnheader(2), \
     "comparaison.dat" using 1:3 title columnheader(3)

