
#   Algorithme d'union-find incrémental avec explications


******************************************************************************

1. Introduction
2. Structures de données
3. Algorithmes
4. Incrémentalité
5. Références

******************************************************************************


1. Introduction
===============

Le module d'union-find incrémental avec explications est une implémentation d'un algorithme d'union-find supportant les opérations suivantes : 

  - empty     : initialiser le module
  - union     : unir les ensembles des deux éléments donnés en argument
  - find      : trouver le représentant de l'ensemble contenant l'élément donné en argument
  - are_equal : indiquer si deux éléments sont dans le même ensemble
  - undo_last : annuler la dernière union effectuée
  - explain   : expliquer pourquoi les deux éléments donnés en arguments sont dans le même ensemble (lorsque c'est le cas !)
  
Les structures de données utilisées sont décrites partie 2. Les algorithmes sont présentés partie 3.


2. Structures de données
========================

La structure d'union-find habituelle est implémentée grâce aux trois structures suivantes : 

  - parents          : associe à chaque noeud son parent direct dans l'ensemble d'union-find
  - parents_compress : associe à chaque noeud un de ses parents dans l'ensemble d'union-find (idéalement la racine)
  - depth            : associe à chaque noeud la profondeur de l'arbre y étant enraciné
    
Afin d'effectuer les opérations undo_last et explain, il est nécessaire d'ajouter les deux structures suivantes :

  - edges      : associe à chaque noeud u de parents ayant un père v l'arête (k,b,x,y) telle que
       * v est devenus parent de x lors de l'appel union(x,y)
       * l'opération union(x,y) a été la kème union effective
       * b est un booléen vraie ssi union(x,y) a nécessité d'augmenter depth(v)
  - edges_real : associe à chaque couple (x,y) figurant dans les images de edges (ie tel que (k,b,x,y) apparaît) le couple (u,v) (unique !) dont (k,b,x,y) est l'image 


3. Algorithmes
==============

Les opérations union, find et are_equal s'effectuent de manière classique, à la différence que l'on maintient les arbres compressés (parents_compress) et non compressés (parents), et que les structures edges et edges_real sont maintenues à jour.

L'opération explain(u,v), lorsque u et v sont dans le même ensemble, renvoie un ensemble minimal (!) d'unions (ui,vi) qui ont conduites à placer u et v dans le même ensemble. L'algorithme prend appuie sur la remarque suivante : soit p le plus petit ancêtre commun à u et v dans parents, soit (k,b,x,y) l'arête possédant le plus grand facteur k sur les chemins menant de u à p et de v à p. Alors l'ensemble des unions suivantes est correct et minimal : 
  - (x,y)
  - explain(u,x) et explain(y,v) OU explain(u,y) et explain(x,v) (appel récursif de explain) 
  
Une présentation détaillée de explain figure dans [1] (paragraphe 2.1), en particulier il est expliqué comment choisir : explain(u,x) et explain(y,v) OU explain(u,y) et explain(x,v).

L'opération undo_last s'effectue de la façon suivante : soit (x,y) les 2 éléments ayant été (effectivement) unis en dernier. Supposons que l'ensemble de x a été rattaché à celui de y (en pratique, il faut effectuer un test pour savoir si ce n'est pas l'inverse). Alors, edges_real permet d'obtenir l'arête (u,v) ajoutée effectivement dans l'arbre lors de l'union. Cette arête permet de rétablir en temps constant les structures parents, depth, edges et edges_real juste avant l'opération union(x,y). La structure parents_compress ne peut cependant pas être rétablie, on substitue parents à parents_compress.

Complexité
----------

Les opérations union, find et are_equal possèdent les complexités habituelles : u unions et f find s'effectuent en temps O((u+f)*alpha(u+f,u)).

L'opération explain s'effectue en temps O(k*log n) où k est la taille de l'explication produite et n le nombre d'éléments présents dans les ensembles considérés (voir [1]). [1] présente également un algorithme en O(k).

L'opération undo_last s'effectue en temps constant.


4. Incrémentalité
=================

L'algorithme d'union-find précédemment décrit est pleinement incrémental. En particulier, l'opération de backtrack s'effectue en temps constant et ne nécessite d'effectuer de sauvegardes au cours du temps.


5. Références
=============

[1] Proof-producing congruence closure (2005) by Robert Nieuwenhuis, Albert Oliveras

Remarque : la fonction undo_last utilise les structures de données introduites dans [1] mais son implémentation ne s'appuie sur aucun papier.

