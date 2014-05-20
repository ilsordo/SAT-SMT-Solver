
#   Algorithme d'union-find incrémental avec explications


******************************************************************************

1. Introduction
2. Structures de données
3. Algorithmes
4. Incrémentalité
5. Références

******************************************************************************

Le module d'union-find incrémental avec explications est une implémentation d'un algorithme d'union-find supportant les opérations suivantes : 

  - empty     : initialiser le module
  - union     : unir les ensembles de deux éléments
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
    
Afin d'obte

