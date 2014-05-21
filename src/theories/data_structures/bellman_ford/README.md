
#   Algorithme de Bellman-Ford incrémental


******************************************************************************

1. Introduction
2. Structures de données
3. Algorithmes
4. Incrémentalité
5. Références

******************************************************************************

 
 
1. Introduction
===============

L'algorithme de Bellman-Ford incrémental est un algorithme de détection de cycles de poids négatifs dans un graphe évolutif possédant des contrainte sur ses sommets. 

Le problème considéré se formule ainsi : étant donné un graphe pondéré orienté G=(V,E) pouvant évoluer au cours du temps (ajouts/suppressions de noeuds/arêtes), associer à chaque sommet u de V une valeur pi(u) telle que pour toute arête (u,v) de E de poids w : pi(x) + w - pi(y) => 0.

Le module joint permet le stockage interne du graphe et l'utilisation de l'algorithme via les fonctions suivantes : 

  - empty       : initialiser le module, avec un graphe vide
  - add_node    : ajouter un noeud au graphe
  - add_edge    : ajouter une arête
  - remove_edge : supprimer une arête
  - relax_edge  : détecter la présence d'un cycle de poids négatif en relaxant une arête
  - neg_cycle   : obtenir un cycle de poids négatif (s'assurer au préalable qu'il en existe un)
  
Les structures de données utilisées sont décrites partie 2. Les algorithmes sont présentés partie 3.


2. Structures de données
========================

Six structures de données sont nécessaires aux algorithmes : 

  - graph            : représentation du graphe par listes d'adjacence. Pour toute arête de a vers b de poids w, le couple (w,b) est ajouté à la liste d'adjacence de a.
  - values           : associe à chaque noeud un potentiel rendant consistant le graphe pour les arêtes déjà relaxées.
  - next_values      : associe à chaque noeud un nouveau potentiel en construction, qui se substitue à values lorsqu'une relaxation est réussie.
  - estimate_static  : associe à chaque noeud u une estimation de next_values(u)-values(u) si la relaxation en cours peut être menée à son terme. 
  - estimate         : stockage de certaines valeurs de estimate_static dans un tas min (structure de Braun Trees).
  - explain          : associe à chaque noeud u l'arête suivant laquelle estimate_static(u) a été modifié. Permet de reconstruire un cycle de poids négatif lorsqu'il en existe un.
  

3. Algorithmes
==============

Les opérations add_node, add_edge et remove_edge se font de manière naïve en modifiant la structure graph, et en associant le potentiel 0 à tout nouveau noeud.

L'opération relax_edge est plus complexe. Elle prend appuie sur l'algorithme de Bellman-Ford incrémental présenté dans [1]. La relaxation d'une arête de poids d de u vers v se fait de la façon suivante : 

```
  relax_edge(u,v,d)
  
1   next_values <- values
    estimate_static <- []
    estimate <- []
    explain <- []
5   estimate_static(v) <- values(u) + d - values(v)
    Si estimate_static(v) < 0 alors
      insert(estimate,values(u) + d - values(v))
      explain(v) <- (u,v,d) 
    Pour w <> v 
10    estimate_static(w) <- 0
    Tant que not isEmpty(estimate) faire
      s <- extractMin(estimate)
      next_values(s) <- values(s) + estimate_static(s)
      estimate_static(s) <- 0
15    Pour toute arête s -> t de poids c faire
        Si next_values(t) = values(t) et (next_values(s) + c - values(t) < estimate_static(t)) alors
          explain(t) <- (s,t,c)
          Si t =u alors
            Retourner "Cycle négatif passant par u"
20        Sinon
            estimate_static(t) <- next_values(s) + c - values(t)
            decrease(estimate,next_values(s) + c - values(t))
      values <- next_values
      Retourner "Relaxation réussie"
```

L'opération neg_cycle consiste uniquement à "remonter", via explain, le cycle de poids négatif détecté ligne 19, en partant du sommet u.

Précisions sur les tas min utilisés
-----------------------------------

Nous avons récupéré une implémentation tierce des Braun Trees afin d'avoir une structure de tas. Nous n'avons pas utilisé de tas de Fibonacci (qui ont une meilleur complexité et fournissent l'opération decrease) afin de ne pas avoir à faire appel à une structure de donnée tierce trop conséquente (l'implémentation, très élémentaire, des Braun Trees occupe une cinquantaine de lignes seulement).

Les Braun Trees ne permettent pas d'effectuer l'opération de la ligne 22 (diminuer une valeur dans le tas). A la place, nous faisons une insertion classique ligne 22, et lors d'une extraction (ligne 12) la valeur extraite est comparée avec celle stockée dans estimate_static : en cas de différence, il s'agit d'une ancienne valeur rendue obsolète ligne 22, elle est donc supprimée sans analyse supplémentaire.
    
Complexité
----------

D'après [1] et [2], chaque opération de relaxation se fait en temps O(m + n*log n) lorsque des tas de Fibonnaci sont utilisés. Nous pensons que les Braun Trees conduisent à une complexité en O(m*log m + n*log n).   
    

4. Incrémentalité
=================

L'incrémentalité est l'intérêt principal des algorithmes et structures de données utilisés ici. En effet, il est possible de construire progressivement le graphe et de vérifier la présence de cycles de poids négatifs sans avoir à exécuter l'algorithme classique de Bellman-Ford en O(m*n).

De plus, lorsqu'une relaxation échoue en découvrant un cycle de poids négatif (ligne 19), les valeurs contenues dans values sont consistantes pour toutes les arêtes relaxées, exceptée la dernière (qui a provoqué l'échec). Ainsi, un fois la dernière arête supprimée, aucune autre modification n'est à effectuer. En particulier, si d'autres arêtes sont supprimées, values n'a pas à subir de changement supplémentaires !

    
5. Références
=============
 
[1] Fast and Flexible Difference Constraint Propagation for DPLL(T) (2006) by Scott Cotton, Oded Maler

[2] Deciding separation logic formulae by SAT and incremental negative cycle elimination (2005) by Chao Wang, Franjo Ivancic, Malay Ganai, Aari Gupta   

Remarque : l'algorithme présenté Fig.1 dans [1] contient une erreur (le tout premier u doit être remplacé par v).
      
      

