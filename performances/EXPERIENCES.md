#   Expériences


******************************************************************************

1. Introduction
2. Effectuer et enregistrer des tests
3. Manipuler des résultats

******************************************************************************

 
timeout
s'attacher à prendre des tests réalistes

1. Introduction
===============

Nous proposons ici une analyse des temps d'exécution obtenus en lançant les 4 algorithmes (WL, DPLL, Tseitin et Colorie) et les 8 heuristiques (...) sur des fichiers de tests générés alétoirement. Le fichier README situé à la racine du projet détaille les processus de génération aléatoires utilisés, ainsi que les principes de fonctionnement des différents algorithmes et heuristiques.

Notre analyse prendra appuie sur les courbes contenues dans le dossier ... Ces courbes sont issues des bases de données présentes dans le dossier ... Le fichier README joint donne de plus amples informations sur ces bases de données (comment les manipuler, comment ont-elles été obtenues...)

Nous expliquerons, partie 2, ce qu'est la phrase transition et en quoi elle a guidé nos choix de tests. Nous détaillerons ensuite partie 3 les temps mis par les différentes heuristiques pour choisir des littéraux sur lesquels parier. Nous analyserons alors, partie 4, les temps de résolution (temps de décision exclu) suivant l'heuristique utilisée.
Enfin, nous nous pencherons sur les algorithmes Tseitin et Colori, et leurs performances suivant les heuristiques utilisées, respectivement parties 5 et 6



2. Phase de transition
======================

Lorsqu'une cnf est générée, elle a 3 propriétés : n (nombre de variables), l (longueur des clauses) et k (nombre de clauses). Il se pose alors la question suivante : qu'est-ce qu'une "bonne" cnf, c'est-à-dire une formule qui sollicitera suffisamment les algorithmes en nécessitant plusieurs paris et en provoquant de nombreux conflits. 

Intuitivement, à n et l fixé, lorsque k est petit il y a peu de contraintes et il sera facile de prouver que la cnf est satisfiables. A l'inverse, lorsque k est élevé, les contraintes sont si nombreuses qu'il va être aisé de montrer que la cnf n'est pas satisfiable. On peut alors s'attendre à observer une "phase de transition" pour la valeur k, dans laquelle les cnf générées seront intéressantes.

Afin d'observer l'existence de la phase de transition, nous avons généré des cnf à n=100 et l=3 fixés, pour k variant de ... à ... L'algorithme utilisé est WL+DLCS. La courbe ... indique ainsi le temps d'exécution suivant la valeur de k. On peut ainsi observer que l'algorithme met le plus de temps à s'exécuter lorsque k est dans l'intervalle ... En dessous et au-dessus de ces valeurs, les temps d'exécutions sont plus faibles. Courbe ... on affiche cette fois-ci le nombre de conflits en ordonnées. La courbe obtenue ressemble fortement à la précédente. Ceci confirme notre hypothèse, à savoir l'existence d'une phase de transition dans laquelle les cnf générées sont particulièrement difficiles.

Courbe ..., on observe que la valeur k=... semble engendrer les cnf les plus difficiles. On a alors ../..=... Il se trouve effectivement qu'à l donné, il existe un facteur f tel que l'ensemble des cnf de la forme (n,l,f*l) tombent systématiquement dans la phase de transition. Ce facteur f nous donne ainsi la possibilité de générer des cnf difficiles à l donné. Nous avons répertorié (ou calculé) quelques uns de ces facteurs : 

...

Pour une valeur de l donnée (et un facteur de transition f correspondant), nous avons testé différents triplés (n,l,f*l) afin d'observer les temps d'exécution lorsque l'on reste au sein de la phase de transition. La courbe ... permet ainsi de constater que l'évolution du temps d'exécution et linéaire (?) en n

prq util



3. Heuristiques et temps de décision
====================================

Avant de s'intéresser à la pertinence des heuristiques dans les choix qu'elles effectues, étudions le temps qu'elles passent à déterminer sur quelles variables parier.

extraction sur 6 min

Observons tout d'abord les résultats sur de courtes formules (3-SAT) pour n=150 et l=3. Nous avons conservé sur la courbe ... les 6 heuristiques ayant les plus grands temps de décision (RAND_MF, RAND_RAND, NEXT_RAND, NEXT_MF, MOMS, JEWA). Il est remarquable que ces heuristiques sont lentes aussi bien avec DPLL qu'avec WL. Les 2 heuristiques restantes, DLIS et DLCS, ont des temps de décision inférieurs à 0.1s sur les tests considérés ici.

Les heuristiques RAND_MF, RAND_RAND, NEXT_RAND, NEXT_MF provoquent soit des timeout subitement (k=600 pour DPLL+RAND_MF/RAND_RAND par exemple, alors que les temps sont inférieurs à ..s pour k=500), soit engendrent des temps de décision proches de la 1s (WL+NEXT_MF/NEXT_RAND sur k=700). Or, ces heuristiques choisissent rapidement les littéraux sur lesquels parier. En effet, les choix aléatoires sont immédiats, le choix de la 1ère variable libre (NEXT) nécessite au plus n opérations, de même que la recherche de la polarité la plus fréquente (MF). Par conséquent, les temps de décision légèrement plus élevée sur ces heuristiques s'expliquent probablement par leur non-pertinence dans le choix des littéraux sur lesquels parier, ce qui engendre de nombreux conflits et paris, et rallonge mécaniquement le temps de décision.

Les temps de décision des heuristiques MOMS et JEWA se distinguent très nettement. WL+MOMS timeout pour k=700 et possède systématiquement le temps de décision le plus élevé (..s pour k=800 alors que le second pire temps est à ...s). Ceci est facilement explicable : cette heuristique est peu naturelle pour WL. En effet, elle nécessite de connaitre le nombre d'occurences de chaque variable. Or, dans WL, les clauses dans lesquelles chaque littéral apparait ne sont pas connus. Par conséquent, WL+MOMS nécessite de reparcourir l'ensemble des clauses à chaque exécution. DPLL+MOMS s'exécute plus rapidement (1s pour k=700). Cet temps peut s'expliquer par la nécessité de rechercher les clauses de taille minimale à chaque exécution (la taille d'une clause s'obtienne en temps constant).

L'heuristique JEWA nécessite de parcourir l'ensemble des clauses afin d'attribuer un score à chaque littéral. Sa complexité temporelle est identique sur WL et JEWA. Toutefois, on peut constater des temps de décision supérieur sur WL (..s pour k=700), alors que DPLL est inférieur à ..s Ceci est difficile à expliquer en l'état, on peut supposer que WL+JEWA ne prend pas de bonnes décisions, ce que l'on pourra confirmer ou non partie 4.

et sur des clauses longues ?

attention : si bcp de conflits, pas un indicateur pertinent

l = select_data(150,nil,nil,["dpll","wl"],["rand_mf","rand_rand","next_rand","next_mf","jewa","moms"],6) { |p,r| ["#{p.algo}+#{p.heuristic}",p.k,r.result.timers["Decision (heuristic) (s)"]/r.count] }

WL+MOMS : le pire, timeout très tôt
DPLL+RAND_MF : timeout rapide, mais plutôt parce que mauvaie (500 aussi)
DPLL+RAND_RAND

timeout sur 700 :
WL+RAND_MF
WL+RAND_RAND
DPLL+NEXT_RAND
DPLL+NEXT_MF

WL + JEWA : le plus parmi ceux qui y arrive, se distingue avec ..s sur le 2e
DPLL+MOMS : proche de la second

WL+NEXT_MF
WL+NEXT_RAND
DPLL+JEWA



4. Heuristiques et temps de résolution
======================================

Nous étudions ici les temps de résolution des heuristiques, c'est-à-dire le temps de résolution privé du temps de décision (étudié partie 3). Ceci nous renseigne sur la pertinence des choix effectués par les heuristiques.

Ceci confirme les hypothèses effectuées partie 3 : les temps de décision plus élevés sur ces heuristiques s'expliquent par l'importance du nombre de conflits
heuristiques idiotes
2 heuristiques bofs
2 heur bonnes


au-dessus de 3/4-sat : trop dur
loin de 100 : aussi
nb de conflits suivant cnf
nb de conflits suivant heur











