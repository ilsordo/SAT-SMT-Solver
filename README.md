
 ######################################################
 #                                                    #
 #   PROJET 2 : Rendu 1                               #
 #                                                    #
 #   Maxime Lesourd                                   #
 #   Yassine HAMOUDI                                  #
 #                                                    #
 ######################################################


Compilation et exécution    
========================

Pour compiler, entrer : 

    make

Pour exécuter le programme sur un fichier ex.cnf, entrer : 

    ./resol ex.cnf 

Pour afficher les informations sur le déroulement de l'algorithme :

    ./resol -d n ex.cnf

où d est un entier positif définissant le niveau de détail de la description (plus d est grand, plus il y aura d'informations)

Pour générer une formule de k clauses de taille l avec n variables dans out.cnf :

    ./gen n l k > out.cnf

Pour le résoudre à la volée :

    ./gen n l k | ./resol 

Pour utiliser l'algorithme watched literals :

    ./resol-wl ex.cnf

Note: resol-wl accepte les mêmes options que resol

Structures de données
=====================

Les structures suivantes sont utilisées par l'algorithme :

clause.ml:
---------

* variable : Les variables sont des entiers

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

Les assignations de valeur dans la formule se traduisent en un passage des clauses validées par le littéral dans la partie cachée
des clauses, une modification des listes d'occurences pour garantir la propriété citée précédemment et une assignation dans les clauses. 

formule_wl.ml:
----------------

* wl_pos et wl_neg : 2 vartable de clauseset permettant de savoir pour chaque littéral dans quelles clauses il apparait.

Algorithme DPLL
===============

L'algorithme DPLL est implémenté comme une alternance de phases de propagation de contraintes et de paris sur des variables libres.

La variable à assigner est choisie comme la première variable non assignée.

La propagation des contraintes est accélérée par la connaissance par la formule des clauses contenant la variable assignée,
On évite ainsi de parcourir toutes les clauses. 

Prétraitement:
--------------

Le prétraitement effectué se limite à supprimer les clauses trivialement satisfiables : celles contenant x et -x.
La première étape de propagation des contraintes n'est jamais annulée (sauf si on ne trouve pas d'assignation) et joue donc le rôle du prétraitement.

Algorithme Watched Literals
===========================

Prétraitement:
--------------

Le prétraitement s'effectue en trois étapes : 
  - suppression des tautologies
  - détection des clauses singletons et affectations des variables constituant ces clauses (avec propagation)
  - détection d'éventuelles clauses vides (ce qui entrainerait l'insatisfaisabilité de la formule)

Une fois la phase de prétraitement terminée (et si elle n'a pas échouée), on garantie alors qu'il est possible d'établir la surveillance de 2 littéraux différents par clause.

Déroulement :
--------------

L'algorithme choisie une variable à assigner puis propage le résultat sur les watch literals : 
Lorsqu'une paire (v1,v2) est surveillée dans une clause c et que l'on vient d'assigner v1 à true, il y a 4 possibilitées (que l'on résume par le type wl_update dans formule_wl.ml) : 
  - conflit : tous les littéraux de la clause sont faux, il faut backtracker et revenir sur le dernier pari
  - v2 est vrai : il n'y a rien à faire
  - on parvient à trouver un nouveau littéral à surveiller, on déplace alors la surveillance de v1 à v2
  - v2 est le seul littéral non faux (et non assigné) de c : on assigne v2 de sorte à satisfaire c, puis on propage

L'étape de backtracking est implémentée en maintenant une liste de toutes les variables instanciées depuis le dernier pari. Lors d'un conflit, on parcourt cette liste pour mettre à "indéfinie" la valeur des variables).
 
Les différents opérations menées prennent appuies sur les deux faits suivants : 
  - A tout instant, chaque clause connait les 2 littéraux qui la surveillent (accès en temps constant à cette information)
  - A tout instant, chaque littéral connait les clauses qu'il surveille

Suivi de l'algorithme
=====================

Un système de suivi de l'algorithme est fourni par le module Debug, il permet d'afficher sélectivement des informations sur le déroulement de l'algorithme en plaçant des appels à 'debug' paramétrés par une profondeur dans le code. Le paramètre -d permet alors d'afficher les informations jusqu'à une certaine profondeur et -b de mettre l'exécution en pause sur certains évènements.

Un système de statistiques permet de compter les appels à certaines parties du code pour détecter les sections les plus utilisées.
Ces statistiques sont affichées à partir de '-d 1'.

La classe formule permet l'évaluation de la formule en utilisant l'assignation calculée si la formule est satisfiable.
Le résultat renvoyé par l'exécutable est donc systématiquement vérifié et le résultat de la vérification est affiché à partir de '-d 1'.

Générateur
==========

Un générateur de clauses est fourni avec le solveur, il génère des clauses uniformément (on extrait les premiers éléments d'une permutation de l'ensemble des variables) et sans tautologie ni doublon de littéraux.


Analyse des performances
========================

Les algorithmes terminent instantanément sur les exemples fournis avec l'énoncé.

Les exemples difficiles sont hard.cnf et gen2.cnf  

Les performances des algorithmes DPLL et WL ont été comparées sur un certain nombre d'entrées. Il est nécessaire de générer des entrées de taille particulièrement grande pour observer une différence dans les temps d'exécutions.

Ci-dessous figurent les temps d'exécutions pour des entrées aléatoires de paramètre n_l_k (n : nombre de variables, l : longueur des clauses, k : nombre de clauses)
On peut constater que l'algorithme WL est plus performant que DPLL sur nos exemples. Bien que ceci soit compréhensible pour des formules contenant de grandes clauses, il est plus surprenant de l'observer sur des formules 3-SAT. La lenteur de DPLL peut s'expliquer par la nécessité de propager toute assignation sur l'ensemble des clauses (ce qui se traduit cacher/montrer de nombreuses clauses/variables), alors que WL ne propage que sur les littéraux surveillés.


50000_3000_2000
DPLL : 49s
WL : 22s

10000_6000_400
DPLL : 18s
WL : 11s

10000_3_400
DPLL : 3s
WL : 2.6s

10000_3_5000
DPLL : 4.8s
WL : 2.3s

10000_3_20000
DPLL : 23s
WL : 1s


