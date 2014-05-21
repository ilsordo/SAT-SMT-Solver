Algorithme DPLL
===============

Le dossier algo contient les principaux outils nécessaires au fonctionnement de DPLL.

Les fonctions principales sont les 3 suivantes, figurant dans algo_parametric.ml : 
  - process : prend une fonction progress en argument qui est : 
      * soit make_bet : faire un pari et propager
      * soit continue_bet : poursuivre des assignations (suite à un backtrack)
    process fait effectuer sa tâche à progress, en déclenchant un backtrack en cas de conflit créé.
  - bet : choisir un litéral sur lequel parier, exécuter progress avec la fonction make_bet correspondante
  - backtrack : backtrack dans DPLL puis renvoie la liste des assignations défaites et une application de process avec continue_bet
