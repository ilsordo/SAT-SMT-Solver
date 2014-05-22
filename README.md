#   PROJET 2 : Rendu 2

#### Maxime LESOURD
#### Yassine HAMOUDI

http://nagaaym.github.io/projet2

Dépendance : menhir

******************************************************************************

1. Compilation et exécution
2. Améliorations
3. Suivi de l'algorithme et debuggage
4. Générateur
5. Structures de données
6. Algorithme DPLL
7. Algorithme Watched Literals
8. Algorithme Tseitin
9. Algorithme Colorie
10. Heuristiques
11. Clause learning
12. Interaction
13. Satisfiability Modulo Theories
14. Performances

******************************************************************************



1. Compilation et exécution
===========================

Pour compiler, entrer : 

    make

DPLL et WL
----------

Exécuter DPLL sur le fichier ex.cnf : 

    ./resol ex.cnf 

Exécuter WL sur le fichier ex.cnf : 

    ./resol-wl ex.cnf 

Clause Learning
---------------

Pour activer le clause learning, ajouter l'option : 

    -cl

Théories
--------

Utiliser la théorie de la différence sur ex.txt : 

    ./resol -diff ex.txt
       
Utiliser la théorie de l'égalité sur ex.txt : 

    ./resol -eq ex.txt
    
Utiliser la théorie de la congruence sur ex.txt :

    ./resol -cc ex.txt
    
Définir une période de propagation k dans la théorie (théorie de l'égalité par exemple) : 

    ./resol -eq -p k ex.txt 
    
Tseitin
-------

Résoudre la formule propositionnelle contenue dans le fichier ex.txt : 

    ./tseitin ex.txt
    
Colorie
-------

Essayer un coloriage à k couleur du graphe ex.col : 

    ./colorie k ex.col 

Interaction
-----------

Pour activer le mode interactif, ajouter l'option : 

    -i
    
Se référer à la partie 12 pour une documentation plus détaillée du mode interactif
        
Générateur
----------

Générer une cnf de k clauses de taille l avec n variables :
  
    ./gen n l k

Générer un formule propositionnelle comportant n variables différentes et c connecteurs (parmi ~,\/,/\,=>,<=>) :

    ./gen -tseitin n c
    
Générer un graphe à n sommets, avec probabilité p d'existence pour chaque arête :

    ./gen -color n p
    
Enregistrer l'entrée générée dans un fichier ex.txt : 
  
    ./gen -tseitin n c > ex.txt
     
Résoudre l'entrée générée à la volée : 

    ./gen -color n p | ./colorie k
                
Options
-------

Affichage des messages d'aide : 

    --help
    
Fixer un algorithme de résolution : 

    -algo [dpll|wl]
    
Fixer une heuristique de résolution : 

    -h [next_rand|next_mf|rand_rand|rand_mf|dlcs|moms|dlis|jewa]
    
Afficher les messages de débuggage de niveau au plus k : 

    -d k
    
Exécuter l'algorithme pas à pas, en stoppant à chaque étape de profondeur k :
(nécessite l'option -d r avec r supérieur à k)

    -b k
    
Enregistrer dans le fichier f la cnf convertie à partir du problème donné en entrée : 

    -print_cnf f
    
Afficher la cnf convertie à partir de l'entrée :
(attention, cette option ne doit pas être exécutée avec ./colorie) 
    
    -print_cnf -
    
Stocker les résultats d'un algorithme dans un fichier res.txt (n'enregistre ni les statistiques, ni les messages de debuggage) : 

    ./resol ex.cnf > res.txt



2. Améliorations
================

Principales améliorations depuis le rendu précédant : 
  - Implémentation d'un solveur SMT paramétré DPLL(T)
  - Implémentation de structures incrémentales d'union-find et de recherche de cycle négatifs dans un graphe (Bellman-Ford)
  - Implémentation des théories de l'égalité, de la différence et de la congruence
  - Transformation de Tseitin en SMT


  
3. Générateur
=============

Le générateur permet d'obtenir des cnf, des formules propositionnelles et des graphes. Les méthodes de génération aléatoire utilisées sont décrites ci-dessous : 

CNF
---

Le générateur prend en entrée 3 entiers : n l k.
Il produit une formule à n variables comportant k clauses de longueur l chacune.
Les clauses sont choisises uniformément (on extrait les l premiers éléments d'une permutation de l'ensemble des variables) et sans tautologie ni doublon de littéraux.

Tseitin
-------

Le générateur prend en entrée 2 entiers : n c.
Il produit une formule propositionnelle à n variables et c connecteurs logiques.
Pour ce faire, l'algorithme récursif suivant est utilisé : 

```
  TSEITIN_RANDOM(n,c)
    Si c=0 alors
      renvoyer une variable choisie aléatoirement entre 1 et n
    Sinon
      choisir aléatoirement un connecteur logique : connect
      Si connect = ~ alors
        renvoyer ~TSEITIN_RANDOM(n,c-1)
      Sinon
        renvoyer TSEITIN_RANDOM(n,(c-1)/2)connectTSEITIN_RANDOM(n,c-1-(c-1)/2)
```

Color
-----

Le générateur prend en entrée un entier n et un flottant p (compris entre 0 et 1).
Il produit un graphe à n sommets pour lequel chaque arête a une probabilité d'existence p.

*Remarque* : le graphe généré ne respecte pas pleinement le format DIMACS. En effet, la ligne "p edge v e" contient systématiquement la valeur 1 pour e (nombre d'arêtes du graphe). En effet, il n'est pas possible de connaitre le nombre d'arêtes que comportera un graphe généré avant d'avoir choisi (aléatoirement) l'ensemble de ses arêtes. Or, il n'est pas judicieux de stocker au cours de la génération l'ensemble des arêtes (afin de les compter à posteriori) puisque ceci ralentirait le temps d'exécution et occuperait trop d'espace mémoire. Les algorithmes que nous utilisons n'utilisent pas la valeur e figurant dans la ligne "p edge v e", nous avons donc fait le choix d'indiquer systématiquement e=1.



4. Suivi de l'algorithme et debuggage
=====================================

L'ensemble des outils de debuggage et de suivi des exécutions figure dans le fichier debug.ml. Une brève description est fournie ci-dessous.

Messages de debuggage
---------------------

La mise en place de messages de debuggage se fait au sein du code en ajoutant des lignes de la forme : 

    debug#p 2 "Propagation : setting %d to %B" var b; 
    
Ici, le message de debuggage est "Propagation : setting var to b" (%d et %B sont remplacé par var et b).
L'entier 2 indique la profondeur de debuggage. Plus la profondeur est élevée, plus le message de debuggage doit indiquer une information précise. Par exemple, le message suivant a une profondeur faible car il renseigne uniquement sur l'algorithme utilisé : 

    debug#p 1 "Using algorithm %s and heuristic %s" config.nom_algo config.nom_heuristic;

Afin d'afficher tous messages de profondeur au plus k lors de l'exécution de l'algorithme, il faut entrer l'option : 

    -d k
  
*A noter* : à partir d'une profondeur de debuggage 1 (-d 1), si le programme renvoie SATISFIABLE, l'assignation des variables obtenue en résultat est vérifiée sur la formule de départ et une ligne "[debug] Check : " indique si cette assignation est bien valide (true ou false).
  
Exécution pas à pas
---------------------

Il est possible de stopper l'algorithme sur certain messages de debuggage. Pour cela, il faut inscrire au sein du code : 

    debug#p 2 ~stops:true "Propagation : setting %d to %B" var b;

Pour afficher tous les messages de debuggage de profondeur au plus k et stopper l'algorithme à chaque message de profondeur l (l <= k) rencontré, entrer l'option : 

    -d k -b l

Statistiques
------------

Différents types de données peuvent être enregistrés au cours de l'algorithme.

Une table de hachage permet d'associer des entiers à des chaines de caractères et d'incrémenter ces entiers. Il suffit pour cela d'inclure la ligne suivante au sein du code : 
 
    stats#record s;
  
Cette ligne a pour conséquence, chaque fois qu'elle est rencontrée, d'incrémenter l'entier associé à la chaine s. Si s ne figure pas dans la table de hachage, il y est ajouté et se voit associer la valeur 1.

Plusieurs statistiques sont actuellement intégrées à notre code, notamment : 
  * nombre de conflits (provoquant un backtracking)
  * nombre de paris effectués
  * nombre de singletons appris lors du clause learning
  * nombre de clauses (non singletons) apprises lors du clause learning

Timers
------

Il est possible d'obtenir des temps d'exécution sur des portions de code.
Un nouveau timer peut être défini et démarré de la façon suivante (au sein du code) : 

    stats#start_timer "Time (s)";
  
Pour arrêter le timer défini ci-dessus : 

    stats#stop_timer "Time (s)";
  
Plusieurs temps d'exécutions sont enregistrés par défaut, notamment : 
  - "Total exécution (s)" : temps total nécessaire à la résolution de la cnf donnée
  - "Reduction (s)" : temps utilisé pour convertir le problème donné en entrée en une cnf (uniquement pour tseitin et colorie)
  - "Decisions (s)" : temps utilisé par les heuristiques pour décider sur quels littéraux parier
  - "Clause learning (s)" : temps nécessaire au calcul des clauses à apprendre (uniquement lorsque clause learning activé)



5. Structures de données
========================

Les structures suivantes sont utilisées par l'algorithme :

clause.ml:
---------

* variable : les variables sont des entiers

* varset : objet représentant un ensemble de variables. Permet de cacher temporairement des variables.

* clause : une clause est un objet qui contient 2 varset : 
              * vpos : l'ensemble des variables apparaissant positivement dans la clause 
              * vneg : l'ensemble des variables apparaissant négativement dans la clause
           Par exemple, pour la clause 1 2 -3, on a vpos={1,2} et vneg={3}
              * wl1 et wl2 : indiquent quels sont les 2 littéraux qui surveillent la clause (utilisée uniquement pour les watched literals)

Les assignations de valeurs dans la clause se traduisent en un passage des littéraux faux dans la partie cachée.

formule.ml:
-----------

* clauseset : objet représentant un ensemble de clauses. Permet de cacher temporairement des clauses.
              Note : On compare les clauses en leur assignant un identifiant unique à leur création.

* 'a vartable : table d'association polymorphique sur les variables

* formule : une formule est un objet qui contient 4 valeurs :
              * nb_var : le nombre de variables apparaissant dans la formule
              * clauses : clauseset contenant les clauses formant la formule
              * paris : un bool vartable correspondant à une assignation partielle des variables
              * x : un compteur permettant de numéroter les clauses

formule_dpll.ml:
----------------

* occurences : 2 vartable de clauseset permettant de savoir où apparait chaque variable selon sa positivité.
               Si aucun pari n'est fait sur la variable ils contiennent la liste des clauses visibles où elle apparait.
               Si un pari a été fait ils contiennent la liste de clauses cachées qu'il faudra restaurer en cas de backtrack.
* level : une vartable d'entiers indiquant pour chaque variable le niveau auquel elle été assignée
* origin : une vartable de clauses indiquant la clause ayant provoqué l'assignation de la variable, lorsque c'est possible

Les assignations de valeur dans la formule se traduisent en un passage des clauses validées par le littéral dans la partie cachée des clauses, une modification des listes d'occurences pour garantir la propriété citée précédemment et une assignation dans les clauses. 

formule_wl.ml:
----------------

* wl_pos et wl_neg : 2 vartable de clauseset permettant de savoir pour chaque littéral dans quelles clauses il apparait.



6. Algorithme DPLL
==================

L'algorithme DPLL est implémenté comme une alternance de phases de propagation de contraintes et de paris sur des variables libres.

La variable à assigner est choisie comme la première variable non assignée.

La propagation des contraintes est accélérée par la connaissance par la formule des clauses contenant la variable assignée,
On évite ainsi de parcourir toutes les clauses. 

Prétraitement :
---------------

Le prétraitement effectué se limite à supprimer les clauses trivialement satisfiables : celles contenant x et -x.
La première étape de propagation des contraintes n'est jamais annulée (sauf si on ne trouve pas d'assignation) et joue donc le rôle du prétraitement.



7. Algorithme Watched Literals
==============================

Prétraitement :
---------------

Le prétraitement s'effectue en trois étapes : 
  - suppression des tautologies
  - détection des clauses singletons et affectations des variables constituant ces clauses (avec propagation)
  - détection d'éventuelles clauses vides (ce qui entrainerait l'insatisfaisabilité de la formule)

Une fois la phase de prétraitement terminée (et si elle n'a pas échouée), on garantie alors qu'il est possible d'établir la surveillance de 2 littéraux différents par clause.

Déroulement :
-------------

L'algorithme choisie une variable à assigner puis propage le résultat sur les watched literals : 
Lorsqu'une paire (v1,v2) est surveillée dans une clause c et que l'on vient d'assigner v1 à true, il y a 4 possibilitées (que l'on résume par le type wl_update dans formule_wl.ml) : 
  - conflit : tous les littéraux de la clause sont faux, il faut backtracker et revenir sur le dernier pari
  - v2 est vrai : il n'y a rien à faire
  - on parvient à trouver un nouveau littéral v3 à surveiller, on déplace alors la surveillance de v1 à v3
  - v2 est le seul littéral non faux (et non assigné) de c : on assigne v2 de sorte à satisfaire c, puis on propage

L'étape de backtracking est implémentée en maintenant une liste de toutes les variables instanciées depuis le dernier pari. Lors d'un conflit, on parcourt cette liste pour remettre à "indéfinie" la valeur des variables.
 
Les différents opérations menées prennent appuies sur les deux faits suivants : 
  - A tout instant, chaque clause connait les 2 littéraux qui la surveillent (accès en temps constant à cette information)
  - A tout instant, chaque littéral connait les clauses qu'il surveille



8. Algorithme Tseitin
=====================

L'algorithme Tseitin permet de convertir une formule propositionnelle en une cnf.

Nous avons choisi les associativités suivantes pour les différents opérateurs logiques :
  * => : right associative
  * <=> : non associative
  * /\,\/ : left associative

Les priorités sont : NOT > AND > OR > IMP > EQU

Exemple : a/\b => c est lu comme (a/\b) => c
  
Le dossier src/tseitin contient l'ensemble des outils mis en place. En particulier, le fichier tseitin.ml contient l'algorithme de conversion.

Etant donné une formule propositionnelle p, l'algorithme Tseitin produit une cnf [p] telle que p et [p] sont équisatisfiables. La taille de [p], ainsi que le temps d'exécution de l'algorithme, sont linéaires en la taille de p.

  

9. Algorithme Colorie
=====================

Etant donné un entier k et un graphe G, l'algorithme Colorie indique si G peut-être colorié à l'aide de k couleurs distincts.
Le dossier src/color contient l'ensemble des outils mis en place à cette fin.

On rappelle ci-dessous la procédure permettant de construire une cnf indiquant si le graphe G=(V,E) peut être colorié avec k couleurs :
  - pour chaque sommet i, on produit la clause i_1 \/ i_2 \/ ... \/ i_k indiquant que i doit se voir attribuer une couleur entre 1 et k
  - pour chaque arête (i,j), pour chaque entier l entre 1 et k, on produit la clause ~i_l \/ ~j_l indiquant que i et j ne doivent pas avoir la même couleur.
  
Etant donné un graphe G=(V,E) et un entier de coloriage k, la cnf produite est donc constituée de |V| clauses de longueurs k, et k*|E| clauses de longueurs 2.
Le temps nécessaire à la production de la cnf est linéaire en la taille de la cnf produite.



10. Heuristiques
===============

Les heuristiques permettent de déterminer le littéral sur lequel effectuer le prochain pari. Les différentes heuristiques implémentées sont décrites ci-dessous.

Heuristiques de choix de polarité
---------------------------------

Etant donnée une variables, ces heuristiques déterminent la polarité à lui joindre (pour obtenir un littéral).

POLARITE_NEXT :
  * renvoie la polarité true

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

Les 2 catégories d'heuristiques décrites ci-dessus peuvent être combinées pour donner lieu à 7 heuristiques de choix de littéral : 

  * NEXT + POLARITE_NEXT          (-h next_next)
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



11. Clause learning
===================

L'implémentation du clause learning a nécessité l'ajout de 4 informations :

Le niveau d'assignation de chaque variable
------------------------------------------

A chaque variable assignée est associé le niveau auquel a eu lieu l'assignation. Le niveau 0 correspond aux assignations inévitables (propagation initiale, apprentissage de clauses singletons...). Chaque pari, et les assignations qui en découlent, constituent un nouveau niveau. Voir le champ "level" dans l'objet formule (formule.ml).

Les clauses à l'origine des assignations
----------------------------------------

Lorsqu'une clause c contient un seul littéral l non faux (et non assigné), on assigne l et on enregistre c comme étant la clause à l'origine de l'assignation de l. Les littéraux assignés du fait d'un pari ou d'une polarité simple n'ont pas de clause d'origine. Voir le champ "origin" dans l'objet formule (formule.ml).

La pile des assignations
------------------------

On appelle "tranche" un littéral parié et l'ensemble des littéraux assignés en conséquence. La pile des tranches constitue un historique complet de l'ensemble des assignations effectuées. Elle permet d'effectuer le backtracking. Voir les types "tranche" et "etat" (dans algo_base.ml).

L'état
------

L'état regroupe le niveau d'assignation courant et la pile des assignations. Voir le type "etat" (dans algo_base.ml).

****

L'implémentation de l'algorithme de clause learning prend appui sur les fonctions suivantes (cf algo.ml) : 

  - conflict_analysis : produit la clause à apprendre en cas de conflit et fournit les informations nécessaires au backtrack
  - undo : permet de défaire plusieurs niveaux d'assignations
  - continue_bet : permet de poursuivre un tranche d'assignations suite à un backtrack non chronologique

L'ajout de clauses en cours d'exécution n'a pas posé de problèmes particuliers. Nous avons utilisé la méthode add_clause présente dans formule_dpll.ml et formule_wl.ml (héritée de formule.ml) qui était déjà utilisée pour construire la formule de départ. Deux remarques peuvent être faites sur l'ajout de clauses : 
  - lorsqu'un clause singleton doit être apprise, on backtrack jusqu'au niveau 0 afin d'effectuer l'assignation dictée par cette clause puis propager. La clause n'est pas ajoutée.
  - dans l'algorithme WL, lorsque l'on doit apprendre un clause c comportant au moins 2 littéraux, on pose les jumelles sur 2 littéraux dont les niveaux d'assignation sont les plus élevés (à noter qu'il existe un unique littéral de plus haut niveau, mais qu'il peut y en avoir plusieurs au 2ème niveau le plus élevé).


La distinction principale entre DPLL et WL réside dans les fonctions de propagations qui leurs sont propres (voir algo_dpll.ml et algo_wl.ml). Nous sommes parvenus à produire un algorithme générale commun à DPLL et WL, avec ou sans clause learning. Voir la fonction algo figurant dans algo.ml.



12. Interaction
===============

Le mode interactif permet de stopper l'algorithme au cours de son exécution et d'obtenir différentes informations sur l'état courant.

Pour activer le mode interactif, ajouter l'option : 

    -i

Options
-------

L'interaction stoppe l'algorithme à chaque conflit rencontré. Différentes options sont alors proposées à l'utilisateur :
  
Reprendre l'exécution jusqu'au prochain conflit : 

    c
    
Reprendre l'exécution et stopper k conflits plus loin : 

    s k
   
Terminer l'exécution : 

    t
   
Afficher l'assignation courante des variables (assignation conflictuelle) et les niveaux auquels elles ont été assignées :
  
    v
    
Enregistrer dans le fichier res.dot le graphe des conflits : 

    g res
    
Enregistrer dans le fichier res.tex la preuve par résolution de la clause à apprendre (clause learning) : 

    r res

Graphe de conflits
------------------       

La commande g res permet d'enregistrer dans le fichier res.dot le graphe des conflits. Pour afficher le graphe, entrer la commande : 

    ./print_graph res

Légende : 
  * noeuds en gris : littéraux assignés à des niveaux antérieurs au niveau de décision courant
  * noeuds en vert : littéral parié au niveau de décision courant
  * noeuds en bleu : littéraux assignés au niveau de décision courant
  * noeuds en orange : unique littéral de la clause apprise assigné au niveau de décision courant
  * noeud vert entouré en orange : littéral parié au niveau de décision courant et unique littéral de la clause apprise assigné au niveau de décision courant
  * zone entourée par des pointillées : ensemble des littéraux de la clause à apprendre

Preuve par résolution
---------------------

La commande r res permet d'enregistrer dans le fichier res.tex la preuve par résolution qui détermine la clause à ajouter. Pour afficher la preuve, entrer la commande : 

    ./print_resol res 

Exemple
-------

Nous donnons ci-dessous un exemple d'utilisation du mode interactif. Nous allons utiliser le fichier ex4.cnf présent dans le dossier tests/cnf avec l'algorithme DPLL (heuristique NEXT_NEXT par défaut : parier true sur le littéral de numéro le plus élevé).

On lance l'exécution avec activation du mode interactif : 

  ./resol tests/cnf/ex4.cnf -i

L'exécution se stoppe avec un conflit détecté dans la clause 41 (-7 8 3).

On entre la commande v pour afficher l'assignation courante des variables. On constate que la clause 41 est bien fausse, et que les 3 variables qui la composent ont été assignées au niveau de décision courant (niveau 4).

On enregistre le graphe des conflits correspondants dans le fichier conf.dot en entrant : g conf. On affiche ensuite ce graphe en entrant la commande : ./print_graph conf (dans un terminal à part). On constate que la clause à ajouter est la clause -8 20 2. Le littéral -8 est l'unique littéral de cette clause assigné au niveau de décision courant. Les littéraux 2 et 20 ont été assignés à des niveaux antérieurs. L'option v nous indique que 2 a été assigné au niveau 0 (assignation nécessaire) et 20 au niveau 1.

On reprend l'exécution de l'algorithme en entrant la commande s 4 afin de reprendre la main 4 conflits plus tard.

Un conflit est détecté dans la clause 34 (-20 7 -10).

On enregistre les graphes des conflits dans conf.dot : g conf. Puis on l'affiche : ./print_graph conf. On constate que la clause à ajouter est 20 19 -17. Par ailleurs, cette clause intègre le littéral assigné au niveau courant (-17).

On termine l'exécution sans reprendre la main, en entrant la commande t.



13. Satisfiability Modulo Theories
==================================

DPLL(T)
-------

L'implémentation du solveur SMT reproduit exactement le schéma DPLL(T). Il correspond à un solveur DPLL paramétré par une théorie T.

L'algorithme peut être découpé en trois grandes parties : 

  - la procédure DPLL : elle correspond à la partie DPLL de l'algorithme. Son implémentation figure dans le dossier algo. Un fichier README joint à ce dossier donne de plus amples informations sur son fonctionnement.
  - la procédure SMT : elle gère la théorie choisie. Son implémentation figure dans le dossier smt. Un fichier README joint à ce dossier donne de plus amples informations sur son fonctionnement. 
  - les structures de données propres à chaque théorie. Elles figurent dans le dossier theories.
  
Incrémentalité
--------------

Nous avons été particulièrement attentifs à l'incrémentalité des structures de données liées à chaque théorie. Ces structures sont décrites plus en détail dans des fichiers README figurant dans le dossier theories (sous-dossiers bellman_ford et union_find). Les remarques qui suivent sont communes à l'ensemble des théories implémentées.

Les structures de données ont été conçues à partir de structures habituelles rendues pleinement incrémentales. Par exemple, l'algorithme de Bellman-Ford implémenté ne correspond pas à l'algorithme habituel en O(m*n) mais à un algorithme modifié en O(m*log m + n*log n) qui tire parti de l'incrémentalité.

Aucune des structures de données ne nécessite de sauvegardes au cours du temps pour effectuer le backtrack (notamment la structure d'union-find).

Les explications fournies par les théories ont été rendues aussi courtes que possible. Par exemple, l'algorithme de Bellman-Ford construit un cycle de poids négatif lorsqu'il en existe un. L'union-find fourni le plus petit ensemble d'unions qui ont conduit à une inconsistance.

  

14. Performances
================

Une étude des performances des différents algorithmes et heuristiques figure dans le dossier "performances". Consulter le fichier README présent dans ce dossier pour de plus amples informations.




