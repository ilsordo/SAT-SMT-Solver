Algorithme DPLL
===============

Le dossier algo contient les principaux outils nécessaires au fonctionnement de DPLL.


Algo_base et Algo_parametric:
-----------------------------

Un module de type Algo_base ( à l'instar de Algo_dpll ou Algo_wl ) décrit le fonctionnement
d'un algorithme de type Dpll qui agit sur un formule en CNF. A partir d'un tel module,
Algo_parametric construit un algorithme dont l'exécution peut être controlée. Ce controle
se fait par le renvoi après chaque étape de l'exécution de fonctions partielles permettant
de poursuivre l'exécution. Des informations sur les assignations effectuées sont aussi
passées à l'appelant.  

Les fonctions principales permettant le contrôle de l'exécution sont: 
  - process : prend une fonction progress en argument qui est :
      * soit make_bet : faire un pari et propager
      * soit continue_bet : poursuivre des assignations (suite à un backtrack)
    process fait effectuer sa tâche à progress, en déclenchant un backtrack en cas de conflit créé.
  - bet : choisir un litéral sur lequel parier, exécuter progress avec la fonction make_bet correspondante
  - backtrack : backtrack dans DPLL puis renvoie la liste des assignations défaites et une application de process avec continue_bet

Algo_parametric est à la base des modules Algo et Smt.

Algo:
-----

Le module Algo est l'exemple le plus simple de l'utilisation de DPLL(T), il ne fait rien de plus que
relancer DPLL à chaque fois que ce dernier cède le contrôle. Il permet la résolution de SAT ainsi que
de COLOR après réduction.

