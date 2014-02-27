
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

où d est un entier positif définissant le niveau de détail de la description

Pour générer une formule de k clauses de taille l avec n variables dans out.cnf :

    ./gen n l k > out.cnf

Pour le résoudre à la volée :

    ./gen k l n | ./resol 

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

Les assignations de valeurs dans la clause se traduisent en un passage des littéraux faux dans la partie cachée.

Note : l'objet clause contient aussi des champs spécifiques à l'algorithme des watched literals, ils seront expliqués plus loin.

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

L'implémentation actuelle de l'algorithme de Watched Literals n'est pas correcte. Nous n'avons pas pu mener le debuggage à terme dans les temps. Une version utilisable sera envoyée dès que possible.

L'implémentation actuelle : 
  - compile
  - peut être lancée sur des fichiers tests (par exemple :  ./resol-wl tests/test1.cnf)
  - intègre des fonctions d'affichages partielles pour faciliter le debuggage (pour le visualiser, entrer :  ./resol-wl tests/test2.cnf -d 1)
 
De nombreux commentaires figurent dans les fichiers algo_wl.ml et formule_wl.ml. 
Les remarques suivantes peuvent être ajoutées : 
  - une phase de prétraitement permet de supprimer les tautologies et d'effectuer tous les assignements entrainés par des clauses singletons. D'éventuels clauses vides sont alors détectées
  - A tout instant, chaque clause connait les 2 littéraux qui la surveille et chaque littéral connait les clauses qu'il surveille



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

L'algorithme termine instantanément sur les exemples fournis avec l'énoncé.

Les exemples difficiles sont hard.cnf et gen2.cnf  
