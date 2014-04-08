#   Expériences


******************************************************************************

1. Introduction
2. Phase de transition
3. Heuristiques et temps de décision
4. Heuristiques et temps de résolution
5. Tseitin
6. Colorie

******************************************************************************

 
 
1. Introduction
===============

Nous proposons ici une analyse des temps d'exécution obtenus en lançant les 4 algorithmes (WL, DPLL, Tseitin et Colorie) et les 8 heuristiques (NEXT_RAND, NEXT_MF, RAND_RAND, RAND_MF, DLCS, MOMS, DLIS, JEWA) sur des fichiers de tests générés alétoirement. Le fichier README situé à la racine du projet détaille les processus de génération aléatoire utilisés, ainsi que les principes de fonctionnement des différents algorithmes et heuristiques.

Notre analyse prendra appuie sur les courbes contenues dans le dossier "courbes". Ces dernières sont issues des bases de données présentes dans le dossier "databases". Le fichier README joint/présent dans le dossier... donne de plus amples informations sur ces bases de données (comment les manipuler, comment ont-elles été obtenues...)

Nous expliquerons, partie 2, ce qu'est la phrase transition et en quoi elle a guidé nos choix de tests. Nous détaillerons ensuite partie 3 les temps de décisions obtenus par les différentes heuristiques pour choisir des littéraux sur lesquels parier. Nous analyserons alors, partie 4, les temps de résolution. Enfin, nous nous pencherons sur les algorithmes Tseitin et Colorie, et nous étudierons leurs performances suivant les algorithmes utilisés, respectivement parties 5 et 6.

Sauf mention contraire, les courbes qui suivent ont été obtenues à partir de 12 passages sur chaque test avec un timeout à 605s. Les points retenus sont issus de la moyenne d'au moins 6 mesures. Ainsi, un point est absent lorsque 7 mesures, ou plus, ont provoqué un timeout.

On rappelle ci-dessous les différentes heuristiques implémentées :

Heuristiques de choix de polarité
---------------------------------

Etant donnée une variables, ces heuristiques déterminent la polarité à lui joindre (pour obtenir un littéral).

POLARITE_RAND :
  * renvoie une polarité aléatoire (true ou false)

POLARITE_MOST_FREQUENT :
  * pour DPLL : renvoie la polarité avec laquelle la variable apparait le plus fréquemment dans la formule
  * pour WL : renvoie la polarité avec laquelle la variable est la plus surveillée dans la formule

Heuristiques de choix de variable
---------------------------------

NEXT :
  * renvoie la prochaine variable non encore assignée (ce choix est déterministe et dépend de l'entier représentant chaque variable)
  
RAND : 
  * renvoie une variable aléatoire non encore assignée

DLCS : 
  * pour DPLL : renvoie la variable apparaissant le plus fréquemment dans la formule
  * pour WL : renvoie la variable la plus surveillée dans la formule
  
Heuristiques de choix de littéral
---------------------------------

On indique pour chaque heuristique l'argument permettant de l'appeler.

Les 2 catégories d'heuristiques décrites ci-dessus peuvent être combinées pour donner lieu à 6 heuristiques de choix de littéral : 

  * NEXT + POLARITE_RAND          (-h next_rand)
  * NEXT + POLARITE_MOST_FREQUENT (-h next_mf)
  * RAND + POLARITE_RAND          (-h rand_rand)
  * RAND + POLARITE_MOST_FREQUENT (-h rand_mf)
  * DLCS + POLARITE_RAND          (cette option n'est pas disponible)
  * DLCS + POLARITE_MOST_FREQUENT (-h dlcs)

On dispose également des heuristiques suivantes : 

MOMS (-h moms)
  * renvoie le littéral apparaissant le plus fréquemment dans les clauses de taille minimum
   
DLIS (-h dlis)
  * pour DPLL : renvoie le littéral qui rend le plus de clauses satisfaites
  * pour WL : renvoie le littéral qui rend le plus de jumelles satisfaites
  
JEWA (Jeroslow-Wang) (-h jewa)
  * attribue à chaque littéral l un score : somme (pour les clauses C contenant l) de (2**-|C|)
  * renvoie le littéral avec le plus grand score



2. Phase de transition
======================

Une cnf est générée à partir de 3 coefficients : n (nombre de variables), l (longueur des clauses) et k (nombre de clauses). Il se pose la question suivante : qu'est-ce qu'une "bonne" cnf, c'est-à-dire une formule qui sollicitera suffisamment les algorithmes en nécessitant plusieurs paris et en provoquant de nombreux conflits. 

Intuitivement, à n et l fixés, lorsque k est petit il y a peu de contraintes et il sera facile de prouver que la cnf est satisfiable. A l'inverse, lorsque k est élevé, les contraintes sont si nombreuses qu'il va être aisé de montrer que la cnf n'est pas satisfiable. On peut alors s'attendre à observer une "phase de transition" pour la valeur k, dans laquelle les cnf générées seront difficiles à résoudre.

Afin d'observer l'existence d'une telle phase, nous avons produits des cnf à n=200 et l=3 fixés, pour k variant de 100 à 3000. L'algorithme utilisé est WL+DLCS. La courbe 1 indique les temps d'exécution obtenus. On peut observer que l'algorithme met le plus de temps à s'exécuter lorsque k est dans l'intervalle [700,1400]. En dessous et au-dessus de ces valeurs, les temps d'exécutions sont plus faibles. Courbe 2 figure le nombre de conflits suivant k. La courbe obtenue ressemble fortement à la précédente (les points absents correspondent à l'absence de conflits). Ceci confirme notre hypothèse, à savoir l'existence d'une phase de transition dans laquelle les cnf générées sont particulièrement difficiles à résoudre.

Courbes 1 et 2, la valeur k=900 engendre les cnf les plus difficiles. On a alors k/n=900/200=4,5. Il se trouve qu'à l donné, il existe un facteur de transition f tel que l'ensemble des cnf de la forme (n,l,f*l) tombent systématiquement dans la phase de transition. Ce facteur f nous donne ainsi la possibilité de générer des cnf difficiles à l donné. Nous avons répertorié (ou calculé) quelques uns de ces facteurs : 

  l   |     f
 -----|-----------
  3   |   4,27
  4   |   9,93 (cf courbe 3)
  5   |   21,11 
  6   |   43,37 
  7   |   87,79
  8   |   176,56
  9   |   354,01
  10  |   708,92

Comme on peut le constater dans le tableau précédant, f croit très rapidement. En pratique, il devient très difficile de résoudre des formules de la forme (100,l,100*f) dès l=5. A fortiori, l'étude de formules comportant de très longues clauses est peu pertinente en l'état. Nous avons fait figurer courbe 4 différents temps d'exécution pour n=2000, l=500 et k variant de 500 à 2000. On peut constater des temps d'exécution très faibles, dix fois inférieurs au temps nécessaires pour générer les formules considérées.

Par conséquent, nous avons axé notre étude sur des problèmes 3-SAT qui permettent de bien échelonner la difficulté. Travailler au coeur de la phase de transition sollicite fortement les différentes heuristiques et permet de bien distinguer leurs performances.



3. Heuristiques et temps de décision
====================================

Avant de s'intéresser à la pertinence des choix effectués par les heuristiques, étudions le temps qu'elles passent à déterminer sur quels littéraux parier (appelés "temps de décision").

Temps de décision élevés
------------------------

Observons tout d'abord les résultats obtenus sur des formules 3-SAT comportant 150 variables. Nous avons conservé sur la courbe 5 les 6 heuristiques ayant les plus grands temps de décision (RAND_MF, RAND_RAND, NEXT_RAND, NEXT_MF, MOMS, JEWA). L'absence de points signifie ici qu'au moins une mesure a provoqué un timeout. Il est remarquable que ces heuristiques sont lentes aussi bien avec DPLL qu'avec WL. Les 2 heuristiques restantes, DLIS et DLCS, ont des temps de décision inférieurs à 0.1s.

Les heuristiques RAND_MF, RAND_RAND, NEXT_RAND et NEXT_MF ont des temps de décision proches de 0.1s hors de la phase de transition. Cependant, elles provoquent brutalement des timeout pour k=600 et k=700. Ce changement soudain du temps de décision peut surprendre, puisque ces heuristiques choisissent rapidement les littéraux sur lesquels parier. En effet, elles nécessitent au plus n opérations pour effectuer un choix. Par conséquent, les temps de décision plus élevés sur ces heuristiques s'expliquent probablement par une non-pertinence des choix qu'elles effectuent, ce qui engendrerait de nombreux conflits et paris, et rallongerait mécaniquement le temps de décision.

Les temps de décision des heuristiques MOMS et JEWA se distinguent très nettement. WL+MOMS timeout de k=600 à k=700 et possède systématiquement le temps de décision le plus élevé (plus de 3s pour k=900 alors que le second pire temps est inférieur à 0.5s). Ceci est facilement explicable : cette heuristique est peu adaptée à WL. En effet, elle nécessite de connaitre le nombre d'occurences de chaque variable. Or, dans WL, il n'y a pas d'accès direct aux clauses contenant un littéral donné. Par conséquent, WL+MOMS nécessite de reparcourir l'ensemble des clauses à chaque exécution. DPLL+MOMS s'exécute plus rapidement (0.75s pour k=700). Ce temps peut s'expliquer par la nécessité de rechercher les clauses de taille minimale à chaque exécution (la taille d'une clause s'obtient en temps constant).

L'heuristique JEWA parcourt l'ensemble des clauses afin d'attribuer un score à chaque littéral. Sa complexité temporelle est identique sur WL et DPLL. Toutefois, on peut constater des temps de décision supérieurs sur WL (3.25s pour k=700), alors que DPLL est inférieur à 0.5s Ceci est difficile à expliquer en l'état, on peut supposer que WL+JEWA ne prend pas de bonnes décisions, ce que l'on pourra confirmer ou non partie 4.

Temps de décisions faibles
--------------------------

Les heuristiques DLIS et DLCS possèdent les temps de décision les plus faibles (systématiquement inférieurs à 0.2s pour les formules utilisées courbe 5) nous ne les avons pas fait figurer sur les courbes précédentes). Ces heuristiques nécessitent au plus n opérations pour décider sur quel littéral parier. Cette rapidité de décision, couplée avec des choix pertinents, peut expliquer les temps peu élevés.

Conclusion
----------

On peut d'ores et déjà constater que certains heuristiques partent avec un handicap. C'est le cas de WL+MOMS et WL+JEWA par exemple, qui ne sont pas adaptés à aux structures de données utilisées. Les heuristiques les plus élémentaires (RAND_MF, RAND_RAND, NEXT_RAND et NEXT_MF) ont des temps des décisions qui fluctuent de manière importante et qui font soupçonner une non-pertinence dans les choix effectués. Le paragraphe suivant va nous permettre d'étudier les performances effectives, indépendamment du temps de décision.



4. Heuristiques et temps de résolution
======================================

Nous étudions ici les temps de résolution des heuristiques, c'est-à-dire le temps mis à résoudre les formules, temps de décision exclu (étudié partie 3). Ceci nous renseigne sur la pertinence des choix effectués par les heuristiques. 

Les résultats qui suivent peuvent inciter à améliorer l'implémentation de certaines heuristiques pour rendre leur temps de décision plus rapide. En effet, même si certaines heuristiques mettent actuellement longtemps à choisir les littéraux sur lesquels parier, peut-être que les choix qu'elles effectuent se révèlent particulièrement pertinents.

*Remarque préliminaire* : il aurait été possible d'étudier le nombre de conflits ou de paris suivant la cnf générée et l'heuristique utilisée. Nous n'avons pas mené cette étude pour deux raisons : 
  - le temps est une quantité plus facile à appréhender que le nombre de conflits
  - comme on peut s'y attendre, les courbes du temps et du nombres de conflits se superposent. On peut le constater courbes 1 et 2 où nous avons respectivement fait figurer le nombre de conflits et le temps de résolution pour n=200, l=3 et k variant de 100 à 3000 (les points absents correspondont à 0 conflits).
  
Heuristiques élémentaires
-------------------------
  
Penchons-nous tout d'abord sur les heuristiques RAND_MF, RAND_RAND, NEXT_RAND et NEXT_MF. Nous avons vu précédemment qu'elles n'obtenaient pas les meilleurs temps de décision, alors qu'il s'agit des heuristiques effectuant des choix le plus rapidement. Nous avons fait figurer leurs temps de résolution sur la courbe 6 (n=150, l=3, k variant de 100 à 2000). On constate, comme on l'avait présupposé partie 3, que ces heuristiques ont des temps de résolution particulièrement élevés. Leur faible efficacité est probablement liée à la faible pertinence des choix qu'elles effectuent. Ainsi, les décisions de RAND_RAND et NEXT_RAND sont totalement décorrélées de la structure de la formule. RAND_MF et NEXT_MF semblent plus pertinentes puisqu'elles attribuent à une variable donnée sa polarité la plus fréquente en priorité. Toutefois, ceci ne semble pas apporter une grande efficacité. On constate par exemple que WL+NEXT_RAND a 3s d'avance sur WL+NEXT_MF pour k=700.

Heuristiques évoluées
---------------------

Observons maintenant les temps de résolution obtenus avec les heuristiques les plus évoluées, à savoir JEWA, MOMS, DLIS et DLCS. La courbe 7 indique les temps de résolution pour n=200, l=3 et k variant de 100 à 2000. On constate tout d'abord que le temps de résolution de WL+MOMS est particulièrement élevé. Ainsi, il y a absence de résultats de k=800 à k=1400. Ceci est à mettre en parallèle avec les temps obtenus sur WL+JEWA, où on a une absence de résultats sur k=900. Les heuristiques MOMS et JEWA prennent appui sur le nombre d'occurences de chaque littéral pour parier ; or, dans WL, le nombre d'occurences est à distinguer du nombre de clauses dans lesquelles chaque littéral est surveillé. En effet, un littéral apparaissant un très grand nombre de fois dans la formule peut très bien n'être surveillé à aucun endroit. Parier sur un tel littéral n'entrainera aucune propagation (déplacement des jumelles, découverte de conflits...), ce qui peut expliquer la non pertinence de MOMS et JEWA sur WL.

L'heuristique DPLL+JEWA obtient le 2ème meilleur temps (10s pour k=900 au coeur de la phase transition). Ainsi, JEWA a une réelle efficacité lorsque la propagation est directement impactée par le choix du littéral (ce qui n'est pas le cas pour WL+JEWA). On constate également que l'utilisation d'un score (score du nombre d'occurences, chaque occurence pondérée par 2**-taille des clauses où le littéral figure) s'avêre plus efficace que l'observation du nombre d'occurences brut (ce que fait DPLL+DLIS). En effet, DPLL+DLIS n'obtient pas de résultats pour k=900, et réalise le 2ème pire temps, juste derrière WL+JEWA.

L'heuristique MOMS se révèle également être particulièrement bien adaptée à DPLL. On a vu partie 3 que la structure de DPLL permettait un meilleur temps de décision sur MOMS que WL. La courbe 7 confirme qu'il en va de même pour le temps de résolution. Ainsi, DPLL+MOMS obtient le 3ème meilleur temps (11.3s pour k=900). De même que pour JEWA ou DLIS, les choix effectués par MOMS entrainent une propagation importante dans DPLL, ce qui augmente visiblement la rapidité d'exécution. Par ailleurs, on constate que MOMS est légèrement moins bon que JEWA. MOMS restreint son choix aux clauses de tailles minimales, ainsi, s'il existe un littéral apparaissant dans de nombreuses clauses excepté la (ou les) clause de taille minimale, MOMS ne pariera pas dessus. Cette situation, qui tend à favoriser JEWA, peut expliquer les temps de résolution différents entre ces deux heuristiques.

Heuristiques et nombre d'occurences
-----------------------------------

Les heuristiques DLIS et DLCS ont de grandes similarités dans leur fonctionnement puisqu'elles consistent toutes les deux à observer les occurences (pour DPLL) ou les littéraux surveillés (pour WL). Les choix de ces heuristiques sont justifiés par le fait qu'en pariant sur un littéral aux occurences nombreuses, la propagation sera très importante et permettra de découvrir rapidement les conflits, ou au contraire de rendre la formule satisfiable. En pratique, on constate que WL+DLIS/DLCS et DPLL+DLCS se classent parmi les 5 meilleurs heuristiques. Toutefois, ces résultats sont à nuancer. En effet, DPLL+DLIS ne donne pas de résultat pour k=900 (courbe 7), et DPLL+DLCS à un temps de résolution supérieur de 17s à WL+DLCS sur k=900. Ainsi, DPLL et DLCS ne sont pas les heuristiques les plus pertinentes sur DPLL, et comme nous l'avons vu précédemment, DPLL+MOMS/JEWA obtiennent de meilleur résultats. A l'inverse, WL+DLIS/DLCS semblent particulièrement bien adaptés à WL, et donnent lieu notamment au meilleur temps de résolution (8.3s pour k=900 avec WL+DLCS). Cette différence entre DPLL et WL réside probablement dans le comportement de surveillance des clauses. Là où DPLL a accès à l'ensemble des clauses où une variable donnée apparait, WL se contente des clauses où le littéral est surveillé. Ceci permet notamment à WL de ne pas effectuer de longues étapes de propagations. On a pu constater, à l'occasion du rendu 1, que WL était plus efficace que DPLL (en l'absence d'heuristiques). Il semble donc naturel de retrouver ici une supériorité de WL lorsqu'une heuristique pertinente lui est jointe.

Enfin, il est intéressant de se pencher spécifiquement sur WL+DLIS et WL+DLCS. Rappelons le comportement de ces 2 heuristiques : DLIS choisit le littéral rendant le plus de jumelles satisfaites, là où DLCS renvoie la variable la plus surveillée (avec une polarité jointe correspondant à la polarité la plus surveillée). Dans un cas extrême DLIS peut choisir une variable surveillée avec une polarité unique. Ceci ne donne alors lieu à aucune propagation. Dans le cas de DLCS, le choix est basé sur les deux polarités de chaque variable. Ainsi, on espère que chaque pari rendra de nombreuses clauses satisfaites (comme c'est le cas pour DLIS), mais qu'il permettra également de détecter d'éventuelles clauses "presque insatisfiables" (ie qui ne permettraient pas d'abandonner une jumelle située sur la négation du littéral que l'on vient de choisir). Expérimentalement, WL+DLCS surpasse bien WL+DLIS. Ainsi, courbe 7 pour k=900, WL+DLCS nécessite 8.5s là où WL+DLIS met 16.1s.

Conclusion
----------

A nouveau, on a pu constater que les performances d'une heuristiqus sont intrinséquement liées aux structures de données et aux algorithmes (DPLL ou WL) utilisés en amont. Ainsi, notre étude des temps de résolution a confirmé que les heuristiques MOMS et JEWA se mariaient mieux avec DPLL, là où DLIS et DLCS s'adaptent bien à WL.

Nous n'avons pas étudié le temps de résolution sur des formules comportant de longues clauses. En effet, comme indiqué partie 2, les seules formules à longues clauses pouvant être résolues par nos algorithmes sont beaucoup trop simples. Par exemple, pour n=2000, l=500 et k variant de 500 à 2000, les temps de résolutions toutes heuristiques confondues sont inférieurs à 1s.



5. Tseitin
==========



6. Colorie
==========

Comparaison des heuristiques:
-----------------------------

Certaines heuristiques se montrent inutilisables sur les instances de COLOR, une comparaison des combinaisons algorithme/heuristique sur une petite instance de COLOR permet de détecter ces heuristiques (fonction color1 de color.rb). L'instance choisie est le 10-coloriage d'un graphe de 20 sommets en faisant varier la densité et en arretant l'exécution au bout de 10 secondes si le résultat n'est pas trouvé. Les résultats de la figure 1 dans le dossier color montre que les algorithmes wl+jewa, wl+moms et dpll+moms voient leur temps d'exécution exploser rapidement. On remarque au passage que les instances très denses sont plus difficile et les tests montrent que certaines instances de densité >= 0.9 peuvent prendre plusieurs minutes.

Influence des paramètres:
-------------------------

On ne garde que les heuristiques dlis et dlcs et on fait varier le nombre de sommets à densité fixée. La figure 2 montre que ces heuristiques sont très proches en terme de performances avec un léger avantage pour dlcs. L'algorithme wl se montre plus performant pour de grands graphes. On utilisera donc cette heuristique et l'algorithme wl pour mesurer l'influence des paramètres n, p et k sur le temps d'exécution.

La figure 3 montre que cet algorithme n'arrive pas à décider si un graphe à n sommets est n/2 coloriable si le graphe est dense (p>=0.5). La difficulté réside dans le fait que ces instances ont très souvent une réponse négative ce qui oblige l'algorithme à revenir sur ses paris très souvent.

Ces résultats confirment la performance de dlis et dlcs au delà de 3-SAT grâce à une propagation rapide des contraintes.
