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

Nous proposons ici une analyse des temps d'exécution obtenus en lançant les 4 algorithmes (WL, DPLL, Tseitin et Colorie) et les 8 heuristiques (NEXT_RAND, NEXT_MF, RAND_RAND, RAND_MF, DLCS, MOMS, DLIS, JEWA) sur des fichiers de tests générés alétoirement. Le fichier README situé à la racine du projet détaille les processus de génération aléatoires utilisés, ainsi que les principes de fonctionnement des différents algorithmes et heuristiques.

Notre analyse prendra appui sur les courbes contenues dans le dossier performances/courbes. Ces courbes sont issues des bases de données présentes dans le dossier performances/databases Le fichier README dans le dossier performances donne de plus amples informations sur ces bases de données (comment les manipuler, comment elles ont été obtenues...)

Nous expliquerons, partie 2, ce qu'est la phase de transition et en quoi elle a guidé nos choix de tests. Nous détaillerons ensuite partie 3 les temps de décision obtenus par les différentes heuristiques pour choisir des littéraux sur lesquels parier. Nous analyserons alors, partie 4, les temps de résolution par heuristique. Enfin, nous nous pencherons sur les algorithmes Tseitin et Colorie, et nous étudierons leurs performances suivant les algorithmes utilisés, respectivement parties 5 et 6.

Sauf mention contraire, les courbes qui suivent ont été obtenues à partir de 12 passages sur chaque test avec un timeout à 605s. Les points retenus sont issus de la moyenne d'au moins 6 mesures. Ainsi, un point est absent lorsque 7 mesures au moins ont provoqué un timeout.

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
  * attribue à chaque littéral l un score : somme (pour les clauses C contenant l) de (2^-|C|)
  * renvoie le littéral avec le plus grand score



2. Phase de transition
======================

Une cnf est générée à partir de 3 coefficients : n (nombre de variables), l (longueur des clauses) et k (nombre de clauses). On peut se poser la question suivante : qu'est-ce qu'une "bonne" cnf, c'est-à-dire une formule qui sollicitera suffisamment les algorithmes en nécessitant plusieurs paris et en provoquant de nombreux conflits. 

Intuitivement, à n et l fixé, lorsque k est petit il y a peu de contraintes et il sera facile de prouver que la cnf est satisfiable. A l'inverse, lorsque k est élevé, les contraintes sont si nombreuses qu'il va être aisé de montrer que la cnf n'est pas satisfiable. On peut alors s'attendre à observer une "phase de transition" pour la valeur k, dans laquelle les cnf générées seront difficiles à résoudre.

Afin d'observer l'existence d'une telle phase, nous avons produits des cnf à n=100 et l=3 fixés, pour k variant de ... à ... L'algorithme utilisé est WL+DLCS. La courbe ... indique ainsi le temps d'exécution suivant la valeur de k. On peut observer que l'algorithme met le plus de temps à s'exécuter lorsque k est dans l'intervalle ... En dessous et au-dessus de ces valeurs, les temps d'exécutions sont plus faibles. Courbe ... figure le nombre de conflits suivant k. La courbe obtenue ressemble fortement à la précédente. Ceci confirme notre hypothèse, à savoir l'existence d'une phase de transition dans laquelle les cnf générées sont particulièrement difficiles à résoudre.

Courbe ..., on observe que la valeur k=... semble engendrer les cnf les plus difficiles. On a alors l/k=../..=... Il se trouve effectivement qu'à l donné, il existe un facteur de transition f tel que l'ensemble des cnf de la forme (n,l,f*l) tombent systématiquement dans la phase de transition. Ce facteur f nous donne ainsi la possibilité de générer des cnf difficiles à l donné. Nous avons répertorié (ou calculé) quelques uns de ces facteurs : 

  l   |     f
 -----|-----------
  3   |   4,27
  4   |   9,93
  5   |   21,11 
  6   |   43,37 
  7   |   87,79
  8   |   176,56
  9   |   354,01
  10  |   708,92

--- A supprimer ?
Pour une valeur de l donnée (et un facteur de transition f correspondant), nous avons testé différents triplés (n,l,f*l) afin d'observer les temps d'exécution lorsque l'on reste au sein de la phase de transition. La courbe ... permet ainsi de constater que l'évolution du temps d'exécution et linéaire (?) en 
---

Comme on peut le constater dans le tableau précédant, f croit très rapidement. En pratique, il devient très difficile de résoudre des formules de la forme (100,l,100*f) dès l=5. Il est utopique d'utiliser le coefficient de transition pour générer des formules à l=100 pour tester le comportement des algorithmes sur de longues clauses. Par conséquent, nous avons axé notre étude sur des problèmes 3-SAT qui permettent de bien échelonner la difficulté. Nous aborderons brièvement le cas des longues clauses, dans le contexte de formules facilement satisfiables.

(cf courbe avec l=4 ?)



3. Heuristiques et temps de décision
====================================

Avant de s'intéresser à la pertinence des choix effectués par les heuristiques, étudions le temps qu'elles passent à déterminer sur quels littéraux parier (appelés "temps de décision").

extraction sur 6 min

Temps de décision élevés
------------------------

Observons tout d'abord les résultats obtenus sur des formules 3-SAT comportant 150 variables. Nous avons conservé sur la courbe ... les 6 heuristiques ayant les plus grands temps de décision (RAND_MF, RAND_RAND, NEXT_RAND, NEXT_MF, MOMS, JEWA). Il est remarquable que ces heuristiques sont lentes aussi bien avec DPLL qu'avec WL. Les 2 heuristiques restantes, DLIS et DLCS, ont des temps de décision inférieurs à 0.1s sur les tests considérés ici.

Les heuristiques RAND_MF, RAND_RAND, NEXT_RAND et NEXT_MF ont soit des temps de décision proches de la 1s (WL+NEXT_MF/NEXT_RAND sur k=700), soit provoquent des timeout subitement (k=600 pour DPLL+RAND_MF/RAND_RAND, alors que les temps sont inférieurs à ..s pour k=500). Or, ces heuristiques choisissent rapidement les littéraux sur lesquels parier. En effet, elles nécessitent au plus n opérations pour effectuer un choix. Par conséquent, les temps de décision légèrement plus élevés sur ces heuristiques s'expliquent probablement par une non-pertinence des choix qu'elles effectuent, ce qui engendrerait de nombreux conflits et paris, et rallongerait mécaniquement le temps de décision.

Les temps de décision des heuristiques MOMS et JEWA se distinguent très nettement. WL+MOMS timeout pour k=700 et possède systématiquement le temps de décision le plus élevé (..s pour k=800 alors que le second pire temps est à ...s). Ceci est facilement explicable : cette heuristique est peu adaptée à WL. En effet, elle nécessite de connaitre le nombre d'occurences de chaque variable. Or, dans WL, il n'y a pas d'accès direct aux clauses contenant un littéral donné. Par conséquent, WL+MOMS nécessite de reparcourir l'ensemble des clauses à chaque exécution. DPLL+MOMS s'exécute plus rapidement (1s pour k=700). Ce temps peut s'expliquer par la nécessité de rechercher les clauses de taille minimale à chaque exécution (la taille d'une clause s'obtient en temps constant).

L'heuristique JEWA parcourt l'ensemble des clauses afin d'attribuer un score à chaque littéral. Sa complexité temporelle est identique sur WL et DPLL. Toutefois, on peut constater des temps de décision supérieurs sur WL (..s pour k=700), alors que DPLL est inférieur à ..s Ceci est difficile à expliquer en l'état, on peut supposer que WL+JEWA ne prend pas de bonnes décisions, ce que l'on pourra confirmer ou non partie 4.

Temps de décisions faibles
--------------------------

Les heuristiques DLIS et DLCS possèdent les temps de décision les plus faibles (inférieurs à ..s, nous ne les avons pas fait figurer sur les courbes précédentes). Ces heuristiques nécessitent au plus n opérations pour décider sur quel littéral parier. Cette rapidité de décision, couplée avec des choix pertinents, peut expliquer les temps peu élevés.

Comportement sur de longues clauses
-----------------------------------

---- A supprimer ?
Terminons en observant quelques résultats sur des cnf avec un facteur l élevé. Nous avons représenté courbe .. différents temps de décision pour n=2000 et l=500, k variant de .. à ... Il faut garder à l'esprit que de telles formules sont "facilement" satisfiables, et provoquent peu de conflits (le coefficient de transition f pour l=500 est si élevé que nos algorithmes actuels ne peuvent pas résoudre de formules de la forme (n,500,f*n)).

WL+JEWA/MOMS crève >> ne pas mettre dans résultat, timeout sur sur 500 (?)
refaire les tests sans eux ?
----



l = select_data(150,nil,nil,["dpll","wl"],["rand_mf","rand_rand","next_rand","next_mf","jewa","moms"],6) { |p,r| ["#{p.algo}+#{p.heuristic}",p.k,r.result.timers["Decision (heuristic) (s)"]/r.count] }



4. Heuristiques et temps de résolution
======================================

Nous étudions ici les temps de résolution des heuristiques, c'est-à-dire le temps mis à résoudre les formules, temps de décision exclu (étudié partie 3). Ceci nous renseigne sur la pertinence des choix effectués par les heuristiques. 

Les résultats qui suivent peuvent inciter à améliorer l'implémentation de certaines heuristiques pour rendre leur temps de décision plus rapide. En effet, même si certaines heuristiques mettent actuellement longtemps à choisir les littéraux sur lesquels parier, peut-être que les choix qu'elles effectuent se révèlent particulièrement pertinents.

*Remarque préliminaire* : il aurait été possible d'étudier le nombre de conflits ou de paris suivant la cnf générée et l'heuristique utilisée. Nous n'avons pas mené cette étude pour deux raisons : 
  - le temps est une quantité plus facile à appréhender que le nombre de conflits
  - comme on peut s'y attendre, les courbes du temps et du nombres de conflits se superposent. On peur le constater courbes .. et .. où nous avons respectivement fait figurer le nombre de conflits et le temps de résolution pour n=.., l=.. et k variant de .. à ..
  
Heuristiques élémentaires
-------------------------
  
Penchons-nous tout d'abord sur les heuristiques RAND_MF, RAND_RAND, NEXT_RAND et NEXT_MF. Nous avons vu précédemment qu'elles n'obtenaient pas les meilleurs temps de décision, alors qu'il s'agit des heuristiques effectuant des choix le plus rapidement. Nous avons fait figurer leurs temps de résolution sur la courbe ... (n=..,l=3, k variant de .. à ..). On constate, comme on l'avait présupposé partie 3, que ces heuristiques ont des temps de résolution particulièrement élevés. Leur faible efficacité est probablement liée à la faible pertinence des choix qu'elles effectuent. Ainsi, les décisions de RAND_RAND et NEXT_RAND sont totalement décorrélées de la structure de la formule. RAND_MF et NEXT_MF semblent plus pertinentes puisqu'elles attribuent à une variable donnée sa polarité la plus fréquente en priorité. Toutefois, ceci apporte peu d'efficacité, comme on peut le constater sur ... ainsi...meilleur...alors que .... moins bon. 

Heuristiques et longueur des clauses
------------------------------------

Observons maintenant les temps de résolution obtenus avec les heuristiques les plus évoluées, à savoir JEWA, MOMS, DLIS et DLCS. La courbe ... indique les temps de résolution pour n=100, l=3 et k variant de ... à ... (8 passages min). On constate tout d'abord que le temps de résolution de WL+MOMS est particulièrement élevé. Ainsi, il y a absence de résultats de k=800 à k=1400. Ceci est à mettre en parallèle avec les temps obtenus sur WL+JEWA, où on a une abscence de résultats sur k=900 et k=1000. Les heuristiques MOMS et JEWA prennent appui sur le nombre d'occurences de chaque littéral pour parier ; or, dans WL, le nombre d'occurences est à distinguer du nombre de clauses dans lesquelles chaque littéral est surveillé. En effet, un littéral apparaissant un très grand nombre de fois dans la formule peut très bien n'être surveillé à aucun endroit. Parier sur un tel littéral n'entrainera aucune propagation (déplacement des jumelles, découverte de conflits...), ce qui peut expliquer la non pertinence de MOMS et JEWA sur WL.

L'heuristique DPLL+JEWA obtient le 2ème meilleur temps (..s pour k=900 au coeur de la phase transition). Ainsi, JEWA a une réelle efficacité lorsque la propagation est directement impactée par le choix du littéral (ce qui n'est pas le cas pour WL+JEWA). On constate également que l'utilisation d'un score (score du nombre d'occurences, chaque occurence pondérée par 2**-taille des clauses où le littéral figure) s'avêre plus efficace que l'observation du nombre d'occurences brut (ce que fait DPLL+DLIS). En effet, DPLL+DLIS n'obtient pas de résultats pour k=900 et k=1000, et réalise le ..ème pire temps, juste derrière WL+JEWA.

L'heuristique MOMS se révèle également être particulièrement bien adaptée à DPLL. On a vu partie 3 que la structure de DPLL se prétait mieux à MOMS que WL quant au temps de décision. La courbe ... confirme qu'il en va de même pour le temps de résolution. Ainsi, DPLL+MOMS obtient le 3ème meilleur temps (..s pour k=900). De même que pour JEWA ou DLIS, les choix effectués par MOMS entrainent une propagation importante dans DPLL, ce qui augmente visiblement la rapidité d'exécution. Par ailleurs, on constate que MOMS est légèrement moins bon que JEWA. MOMS restreint son choix aux clauses de tailles minimales, ainsi, s'il existe un littéral apparaissant dans de nombreuses clauses excepté la (ou les) clause de taille minimale, MOMS ne pariera dessus. Cette situation, qui tend à favoriser JEWA, peut expliquer les temps de résolution différents entre ces deux heuristiques.

Heuristiques et nombre d'occurences
-----------------------------------

Les heuristiques DLIS et DLCS ont de grandes similarités dans leur fonctionnement puisqu'elles consistent toutes les deux à observer les occurences (pour DPLL) ou les littéraux surveillés (pour WL). Les choix de ces heuristiques sont justifiés par le fait qu'en pariant sur un littéral aux occurences nombreuses, la propagation sera très importante et permettra de découvrir rapidement les conflits, ou au contraire de rendre la formule satisfiable. En pratique, on constate que WL+DLIS/DLCS et DPLL+DLCS se classent parmi les 5 meilleurs heuristiques. Toutefois, ces résultats sont à nuancer. En effet, DPLL+DLIS ne donne pas de résultat pour k=900, et DPLL+DLCS a un temps de résolution supérieur de ..s à WL+DLCS sur k=900. Ainsi, DPLL et DLCS ne sont pas les heuristiques les plus pertinentes sur DPLL, et comme nous l'avons vu précedemment, DPLL+MOMS/JEWA obtiennent de meilleur résultats. A l'inverse, WL+DLIS/DLCS semblent particulièrement bien adaptés à WL, et donnent lieu notamment au meilleur temps de résolution (..s pour k=900 avec WL+DLCS). Cette différence entre DPLL et WL réside probablement dans le comportement de surveillance des clauses. Là où DPLL a accès à l'ensemble des clauses où une variable donnée apparait, WL se contente des clauses où le littéral est surveillé. Ceci permet notamment à WL de ne pas effectuer de longues étapes de propagations. On a pu constater, à l'occasion du rendu 1, que WL était plus efficace que DPLL (en l'absence d'heuristiques). Il semble donc naturel de retrouver ici une supériorité de WL lorsqu'une heuristique pertinente lui est jointe.

Enfin, il est intéressant de se pencher spécifiquement sur WL+DLIS et WL+DLCS. Rappelons le comportement de ces 2 heuristiques : DLIS choisi le littéral rendant le plus de jumelles satisfaites, là où DLCS renvoie la variable la plus surveillée (avec une polarité jointe correspondant à la polarité la plus surveillée). Dans un cas extrème DLIS peut choisir une variable surveillée avec une polarité unique. Ceci ne donne alors lieu à aucune propagation. Dans le cas de DLCS, le choix est basé sur les deux polarités de chaque variable. Ainsi, on espère que chaque pari rendra de nombreuses clauses satisfaites (comme c'est le cas pour DLIS), mais qu'il permettra également de détecter d'éventuelles clauses "presque insatisfiables" (ie qui ne permettraient pas d'abandonner une jumelle située sur la négation du littéral que l'on vient de choisir). Expérimentalement, WL+DLCS surpasse bien WL+DLIS. Ainsi .... (utilisé courbe + puissante...)

Conclusion
----------

A nouveau, on a pu constater que les performances d'une heuristiqus sont intrinséquement liées aux structures de données et aux algorithmes (DPLL ou WL) utilisés en amont. Ainsi, notre étude des temps de résolution a confirmé que les heuristiques MOMS et JEWA se mariaient mieux avec DPLL, là où DLIS et DLCS s'adaptent bien à WL.

Nous n'avons pas étudié le temps de résolution sur des formules comportant de longues clauses. En effet, comme indiqué partie 2, les seules formules à longues clauses pouvant être résolues par nos algorithmes sont beaucoup trop simple. Par exemple, pour n=..., l=... et k variant de ... à ... (dont les temps de décision ont été reporté courbe ...), les temps de résolutions toutes heuristiques confondues sont inférieurs à ...s



5. Tseitin
==========



6. Colorie
==========





