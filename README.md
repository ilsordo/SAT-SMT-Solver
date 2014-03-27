
#   PROJET 2 : Rendu 2

#### Maxime LESOURD
#### Yassine HAMOUDI



******************************************************************************

1. Compilation et exécution    
2. Debuggage et exécution pas à pas
3. Structures de données
4. Algorithme DPLL
5. Algorithme Watched Literals
6. Suivi de l'algorithme
7. Générateur
8. Analyse des performances

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

Tseitin
-------

Résoudre la formule propositionnelle contenue dans le fichier ex.txt : 

    ./tseitn ex.txt
    
Colorie
-------

Essayer un coloriage à k couleur du graphe ex.col : 

    ./colorie k ex.col 
    

Générateur
----------

Générer une cnf de k clauses de taille l avec n variables :
  
    ./gen n l k

Générer un formule propositionnelle comportant n variables différentes et c connecteurs (parmi ~,\/,/\,=>,<=>) :

    ./gen -tseitin n c
    
Générer un graphe à n sommets, avec probabilité p d'existence pour chaque arête :

    ./gen -color n p
    
Enregistrer l'entrée générée dans un fichier ex.cnf : 
  
    ./gen -tseitin n c > ex.txt
     
Résoudre l'entrée générée à la volée : 

    ./gen -color n p | ./colorie     
        
Options
-------

Affichage des messages d'aide : 

    --
    
Fixer un algorithme de résolution : 

    -algo [dpll|wl]
    
Fixer une heuristique de résolution : 

    -h [dlis|...]
    
Afficher les messages de débuggage de niveau au plus k : 

    -d k
    
Exécuter l'algorithme pas à pas, en stoppant à chaque étape de profondeur k :
(nécessite l'option -d r avec r supérieur à k)

    -b k
    
Enregistrer dans le fichier f la cnf convertie à partir de l'entrée : 

    -print_cnf f
    
Afficher la cnf convertie à partir de l'entrée :   
(attention, cette option ne doit pas être exécutée avec ./colorie) 
    
    -print_cnf -
    


2. Suivi de l'algorithme et debuggage
=====================================

L'ensemble des outils de debuggage et de suivi des exécutions figurent dans le fichier debug.ml. Une brève description est fournie ci-dessous.

Messages de debuggage
---------------------

La mise en place de messages de debuggage se fait au sein du code en ajoutant des lignes de la forme : 

    debug#p 2 "Propagation : setting %d to %B" var b; 
    
Ici, le message de debuggage est "Propagation : setting var to b" (%d et %B sont remplacé par var et b).
L'entier 2 indique la profondeur de debuggage. Plus la profondeur est élevée, plus le message de debuggage doit indiquer une information précise. Par exemple, le message suivant à la profondeur la plus faible puisqu'il indique uniquement l'algorithme utilisé : 

    debug#p 1 "Using algorithm %s and heuristic %s" config.nom_algo config.nom_heuristic;

Afin d'afficher tous messages de profondeur au plus k lors de l'exécution de l'algorithme, il faut entrer l'option : 

    -d k
  
Enfin, à partir d'une profondeur de debuggage 1 (-d 1), si le programme renvoie SATISFIABLE, l'assignation des variables obtenue en résultat est vérifiée sur la formule de départ et une ligne "[debug] Check : " indique si cette assignation est bien valide (true ou false).
  
Exécution pas à pas
---------------------

Il est possible de stopper l'algorithme sur certain messages de debuggage. Pour cela, il faut inscrire au sein du code : 

    debug#p 2 ~stops:true "Propagation : setting %d to %B" var b;

Pour afficher tous les messages de debuggage de profondeur au plus k et stopper l'algorithme à chaque message de profondeur l (l >= k) rencontré, entrer l'option : 

    -d k -b l

Statistiques
------------

Différents types de données peuvent être enregistrés au cours de l'algorithme.

Une table de hashage permet d'associer des entiers à des strings et d'indenter ces entier. Il suffit pour cela d'inclure la ligne suivante au sein du code :  
 
    stats#record s;
  
Cette ligne à pour conséquence, chaque fois qu'elle est rencontrée, d'indenter l'entier associé au string s. Si s ne figure pas dans la table de hashage, il est ajouté et se voit associer la valeur 1.

Deux statistiques sont actuellement intégrées à notre code : 
  * nombre de conflits (provoquant un backtracking)
  * nombre de paris effectués

Timers
------

Il est possible d'obtenir des temps d'exécution sur des portions de code.
Un nouveau timer peut être définie et démarré de la façon suivante (au sein du code) : 

    let timer = stats#get_timer "Time (s)"
  
Pour arrêter le timer définie ci-dessus : 

    timer#stop;
  



3. Structures de données
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

Les assignations de valeur dans la formule se traduisent en un passage des clauses validées par le littéral dans la partie cachée
des clauses, une modification des listes d'occurences pour garantir la propriété citée précédemment et une assignation dans les clauses. 

formule_wl.ml:
----------------

* wl_pos et wl_neg : 2 vartable de clauseset permettant de savoir pour chaque littéral dans quelles clauses il apparait.



4. Algorithme DPLL
==================

L'algorithme DPLL est implémenté comme une alternance de phases de propagation de contraintes et de paris sur des variables libres.

La variable à assigner est choisie comme la première variable non assignée.

La propagation des contraintes est accélérée par la connaissance par la formule des clauses contenant la variable assignée,
On évite ainsi de parcourir toutes les clauses. 

Prétraitement:
--------------

Le prétraitement effectué se limite à supprimer les clauses trivialement satisfiables : celles contenant x et -x.
La première étape de propagation des contraintes n'est jamais annulée (sauf si on ne trouve pas d'assignation) et joue donc le rôle du prétraitement.



5. Algorithme Watched Literals
==============================

Prétraitement:
--------------

Le prétraitement s'effectue en trois étapes : 
  - suppression des tautologies
  - détection des clauses singletons et affectations des variables constituant ces clauses (avec propagation)
  - détection d'éventuelles clauses vides (ce qui entrainerait l'insatisfaisabilité de la formule)

Une fois la phase de prétraitement terminée (et si elle n'a pas échouée), on garantie alors qu'il est possible d'établir la surveillance de 2 littéraux différents par clause.

Déroulement :
--------------

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


5. Algorithme Tseitin
=====================

L'algorithme Tseitin permet de convertir une formule propositionnelle en une cnf.
Le dossier src/tseitin contient l'ensemble des outils mis en place à cette fin. En particulier, le fichier tseitin.ml contient l'algorithme de conversion.

COMPLEXITE ESPACE+TEMPS



5. Algorithme Colorie
=====================

L'algorithme Colorie indique, pour un entier k et un graphe G, si G peut-être colorié à l'aide de k couleurs distincts.
Le dossier src/color contient l'ensemble des outils mis en place à cette fin.

On rappelle ci-dessous la procédure permettant de construire une cnf indiquant si le graphe G=(V,E) peut être colorié avec k couleurs :
  - pour chaque sommet i, on produit la clause i_1\/i_2\/...\/i_k indiquant que i doit se voir attribuer une couleur entre 1 et k
  - pour chaque arête (i,j), pour chaque entier l entre 1 et k, on produit la clause ~i_l\/~j_l indiquant que i et j ne doivent pas avoir la même couleur.
  
COMPLEXITE ESPACE+TEMPS



6. Heuristiques
===============

Les heuristiques permettent de déterminer le littéral sur lequel effectuer le prochain pari. Les différentes heuristiques implémentées sont décrites ci-dessous. Une analyse comparative de leurs performances figure.... 

Heuristiques de choix de polarité
---------------------------------

Etant donnée une variables, ces heuristiques déterminent la polarité à lui joindre (pour obtenir un littéral).

POLARITE_RAND :
  renvoie une polarité aléatoire (true ou false)

POLARITE_MOST_FREQUENT :
  renvoie la polarité avec laquelle la variable apparait le plus fréquemment dans la formule

Heuristiques de choix de variable
---------------------------------

NEXT :
  renvoie la prochaine variable non encore assignée (ce choix est déterministe et dépend de l'entier représentant chaque variable)
  
RAND : 
  renvoie une variable aléatoire non encore assignée

DLCS : 
  renvoie la variable apparaissant le plus fréquemment dans la formule

Heuristiques de choix de littéral
---------------------------------

On indique pour chaque heuristique l'argument permettant de l'appeler (voir section ...)

Les 2 catégories d'heuristiques décrites ci-dessous peuvent être combinées pour donner lieu à 6 heuristiques de choix de littéral : 

  NEXT + POLARITE_RAND          (-h next_rand)
  NEXT + POLARITE_MOST_FREQUENT (-h next_mf)
  RAND + POLARITE_RAND          (-h rand_rand)
  RAND + POLARITE_MOST_FREQUENT (-h rand_mf)
  DLCS + POLARITE_RAND          (cette option n'est pas disponible)
  DLCS + POLARITE_MOST_FREQUENT (-h dlcs)
  
On dispose également des heuristiques suivantes : 

  MOMS (-h moms)
    renvoie le littéral apparaissant le plus fréquemment dans les clauses de taille minimum
    
  DLIS (-h dlis)
    pour DPLL : renvoie le littéral qui rend le plus de clauses satisfaites
    pour WL : renvoie le littéral qui rend le plus de jumelles satisfaites
    
  JEWA (-h jewa)
    attribue à chaque littéral l un score : somme (pour les clauses C contenant l) de (2**-|C|)
    renvoie le littéral avec le plus grand score



7. Générateur
=============

Le générateur permet d'obtenir des cnf, des formules propositionnelles et des graphes. Les méthodes de génération aléatoire sont décrites ci-dessous : 

CNF
---

Le générateur prend en entrée 3 entiers : n l k
Il produit une formule à n variables comportant k clauses de longueur l chacune.
Les clauses sont choisises uniformément (on extrait les l premiers éléments d'une permutation de l'ensemble des variables) et sans tautologie ni doublon de littéraux.

Tseitin
-------

Le générateur prend en entrée 2 entiers : n c
Il produit une formule propositionnelle à n variables et c connecteurs logiques.
Pour ce faire, l'algorithme récursif suivant est utilisé : 

  TSEITIN_RANDOM(n,c)
    Si c=0 alors
      renvoyer une variable choisie aléatoirement entre 1 et n
    Sinon
      choisir aléatoirement un connecteur logique connect
      Si connect=~ alors
        renvoyer ~TSEITIN_RANDOM(n,c-1)
      Sinon
        renvoyer TSEITIN_RANDOM(n,(c-1)/2)connectTSEITIN_RANDOM(n,c-1-(c-1)/2)

Color
-----

Le générateur prend en entrée 1 entier n et un flottant p.
Il produit un graphe à n sommets pour lequel chaque arête a une probabilité d'existence p.
Remarque : le graphe généré ne respecte pas pleinement le format DIMACS. En effet, la ligne "p edge v e" contient systématiquement la valeur 1 pour e (nombre d'arêtes du graphe). En effet, il n'est pas possible de connaitre le nombre d'arêtes que comportera un graphe généré avant d'avoir choisi (aléatoirement) l'ensemble de ses arêtes. Or, il n'est pas judicieux de stocker au cours de la génération l'ensemble des arêtes (afin de les compter à posteriori) puisque ceci ralentirait le temps d'exécution et occuperait trop d'espace mémoire. Les algorithmes que nous utilisons n'utilisent pas la valeur e figurant dans la ligne "p edge v e", nous avons donc fait le choix d'indiquer systématiquement e=1.

