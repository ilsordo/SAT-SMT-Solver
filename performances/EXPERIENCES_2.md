#   Expériences 2


******************************************************************************

1. Introduction
2. Temps d'exécution
3. Temps de propagation et de backtrack
4. Nombre de conflits
5. Conclusion

******************************************************************************


 
 
1. Introduction
===============

Nous proposons ici une analyse des temps d'exécution obtenus en lançant les algorithmes WL et DPLL, avec ou sans clause learning, et en utilisant les combinaisons d'heuristiques suivantes : DPLL+MOMS, DPLL+JEWA, DPLL+DLCS, WL+DLCS, WL+JEWA. Nous avons basé notre choix d'heuristiques sur les résultats d'expériences du rendu précédant, afin de ne conserver que les plus pertinentes (cf EXPERIENCES_1.md).

Notre analyse prendra appui sur des courbes contenues dans le dossier "courbes/cnf". Ces dernières sont issues des bases de données présentes dans le dossier "databases/cnf". Le fichier README présent dans le dossier performances donne de plus amples informations sur ces bases de données (comment les manipuler, comment ont-elles été obtenues...).

Il s'agit d'étudier l'apport du clause learning sur nos différentes heuristiques. Nous analyserons, partie 2, les temps d'exécution bruts des différents algorithmes. Nous nous intéresserons plus particulièrement aux temps de propagation et de backtrack partie 3. Enfin, nous nous pencherons sur le nombre de conflits rencontrés suivant l'algorithme utilisé, partie 4.

Les tests ont été effectués sur des formules 3-SAT comportant 200 variables et un nombre de clauses compris entre 500 et 1500. Nous nous sommes restreints aux tests mettant le plus à l'épreuve notre solveur, et pouvant être résolu en un temps raisonnable (voir expériences du rendu précédant pour plus d'explications). Sauf mention contraire, les courbes qui suivent ont été obtenues à partir de 12 passages sur chaque test avec un timeout à 700s.



2. Temps d'exécution
====================

Etudions tout d'abord le temps d'exécution total en présence ou non du clause learning. La courbe 12 regroupe les résultats utiles à cette fin.

On constate un ralentissement systématique de l'exécution lorsque le clause learning est activé. Ce ralentissement peut être modéré (pour k=900 : +3s pour DPLL+DLCS, +8s pour DPLL+JEWA), mais également très marqué (pour k=900 : +130s pour DPLL+MOMS, +60s pour WL+DLCS, pour k=1100 : +77s pour WL+JEWA). Le clause learning n'améliore donc pas les performances globales des algorithmes utilisés. 

On peut constater que le clause learning modifie la hiérarchie entre heuristiques. Ainsi, si l'heuristique WL+DLCS est la plus performante en l'absence de clause learning, elle est distancée de près de 50s par DPLL+JEWA et DPLL+DLCS lorsque le clause learning est activé. Ce dernier semble favoriser l'algorithme DPLL par rapport à WL.

En l'état, ces résultats semblent indiquer une inefficacité du clause learning. Toutefois, nous essaierons de localiser plus précisement la source de ralentissement et nous nuancerons ces propos dans les parties qui suivent.



3. Temps de propagation et de backtrack
=======================================

Nous avons essayé d'isoler la cause principale de ralentissement. Tout d'abord, on constate que l'analyse de conflit (en vue de produire les clauses à apprendre) nécessite peu de temps (2s au maximum sur les tests considérés ici). Par ailleurs, le temps de décision (temps nécessaire pour choisir un littéral sur lequel parier) a déjà été étudié dans le rendu précédant (cf EXPERIENCES_1.md) et peut expliquer tout au plus les résultats très élevés de WL+JEWA (avec ou sans clause learning). La raison pour laquelle le clause learning ralenti l'exécution se trouve dans une autre étape de l'algorithme, que nous présentons ici.

La courbe 13 regroupe les temps de propagation pour WL/DPLL+DLCS et DPLL+MOMS. On constate que le clause learning produit des résultats similaires à ceux de la courbe 12, à savoir un allongement du temps de propagation. La courbe 14 comporte quant à elle les temps de backtrack.

On peut remarquer que les temps de backtrack pour WL sont quasiment nuls, en effet l'algorithme WL requiert peu d'opérations lors du backtracking (il n'est pas nécessaire de bouger les jumelles par exemple). A l'inverse, le backtracking est une étape importante de DPLL qui nécessite de rétablir des clauses cachées (car satisfaites) et des occurences de littéraux cachés (car faux). Ceci se traduit par des temps de backtracking non négligeables et très proche des temps de propagation (par exemple, pour k=900, 53s de propagation et 68s de backtracking pour DPLL+MOMS).

La somme des temps de propagation et de backtrack constitue l'essentiel du temps d'exécution. Ainsi WL+DLCS avec clause learning nécessite 66s de propagation (pour k=900) sur un temps total de 69s (cf courbe 12), et DPLL+MOMS (avec clause learning) prend 121s sur 157s. Aussi bien avec clause learning que sans, propagation et backtracking constituent les étapes les plus dispendieuses de nos algorithmes.



4. Nombre de conflits
=====================

Deux facteurs peuvent expliquer une propagation (et backtrack) importante : soit l'algorithme utilisé est particulièrement inefficace et ne parvient pas à trouver la solution rapidement (beaucoup de conflits rencontrés, beaucoup de paris à essayer), soit le nombre et la taille des clauses sont conséquents. Cette deuxième hypothèse pourrait s'appliquer au clause learning qui ajoute des clauses au cours de l'exécution.

La courbe 15 comporte le nombre de conflits obtenus en moyenne, en fonction de l'algorithme utilisé. 

On constate qu'il y a beaucoup moins de conflits engendrés lorsque le clause learning est activé. Ainsi, pour k=900, le clause learning permet de passer de 6500 à 1000 conflits pour DPLL+JEWA, de 10500 à 1500 pour DPLL+DLCS et de 23100 à 12500 pour WL+DLCS. Ces résultats permettent d'exclure la première hypothèse ci-dessus : le clause learning améliore nettement la pertinence de l'algorithme dans les paris qu'il effectue.

Par conséquent, c'est la deuxième hypothèse qui est à retenir. Le ralentissement introduit par le clause learning s'explique par la longueur et le nombre de clauses à traiter. En effet, il faut garder à esprit que dans l'implémentation actuelle du clause learning, un conflit = une clause ajoutée. Par exemple, DPLL+JEWA avec clause learning (k=900) nécessite l'ajout de 1500 clauses en moyennes. La pertinence du clause learning (moins de conflits rencontrés) ne permet pas de palier à la lenteur induite par ces ajouts de clauses.



5. Conclusion
=============

Les résultats obtenus grâce à l'implémentation du clause learning peuvent sembler assez décevants en l'état. Le clause learning ralentit en effet plus ou moins fortement le temps d'exécution. Toutefois, l'analyse du nombre de conflits témoigne d'une réelle pertinence de cette heuristique. Le principal défaut provient de l'apprentissage d'un nombre excessifs de clauses qui ralentit considérablement la propagation.

Nous pensons que le clause learning a un réel intérêt lorsqu'il est couplé avec une heuristique de gestion des clauses apprises. Il faudrait ainsi controler et limiter le nombre de clauses ajoutées. Nous envisageons d'implémenter dans le futur une heuristique de vieillissement des clauses apprises, qui permettrait la suppression de certaines d'entre elles sous certaines conditions.



Addendum
========

Il y a une remarque intéressante concernant DPLL et WL que nous n'avions pas évoquée dans le rendu précédant, et qui a été mise en valeurs dans les expériences menées ici. Il est précisé rendu 2 (cf EXPERIENCES_1.md) que WL est globalement plus rapide que DPLL (WL+DLCS constitue le meilleur algorithme en pratique, en l'abscence de clause learning). On peut constater que le clause learning bouscule cette hiérarchie et donne l'avantage à DPLL.

C'est l'analyse du nombre de conflits qui fournit une explication à ce phénomène. Avec ou sans clause learning, DPLL génère bien moins de conflits que WL. Lorsque le clause learning n'est pas activé, DPLL ne parvient pas à tirer avantage de cela sur WL pour rattraper le temps passé dans la propagation. Cependant, dans la version actuelle du clause learning, il est primordiale de générer aussi peu de clauses que possible. A ce jeu, WL est bien moins bon que DPLL et produit par exemple 12500 clauses (avec DLCS, pour k=900), contre 1500 pour DPLL sur le même exemple. Ceci provoque une inversion des performances : la rapidité de propagation de WL ne suffit pas pour palier à un ajout excessif de clauses, et DPLL prend l'avantage.

En conclusion, une amélioration significative des performances pourrait être obtenue en mariant la rapidité de propagation de WL avec la pertinence des choix effectués par DPLL. Pour ce faire, nous essayons de développer une heuristique sur WL qui modifierait périodiquement l'emplacement de l'ensemble des jumelles afin d'accroitre la pertinence des littéraux surveillés.




