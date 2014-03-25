reset

set title "#{title}"
set xlabel "#{xlabel}"
set ylabel "#{ylabel}"

set style data linespoints

set pointsize 1

plot for [i=2:#{ncols}] "#{data}" using 1:i title columnheader(i)

exit
