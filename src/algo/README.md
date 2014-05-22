Algorithme DPLL
===============

Le dossier algo contient les principaux outils nécessaires au fonctionnement de DPLL.

Le fichier algo_parametric contient les fonctions principales communes à tout solver DPLL. Les 3 principales sont : 
  - process : prend une fonction progress en argument qui est : 
      * soit make_bet : faire un pari et propager
      * soit continue_bet : poursuivre des assignations (suite à un backtrack)
    process fait effectuer sa tâche à progress, en déclenchant un backtrack en cas de conflit créé.
  - bet : choisit un littéral sur lequel parier, exécute process avec progress = make_bet
  - backtrack : backtrack dans DPLL puis renvoie la liste des assignations défaites et une application de process avec progress = continue_bet
  
  
Le fichier algo_base contient le squelette général de tout solver SMT. Actuellement, nous implémentons le solver DPLL et le solver WL. Le module algo contient un foncteur qui, étant donné un solver (DPLL ou WL), ordonnance les tâches à effectuer pour résoudre un problème cnf.
  
  
Le fichier conflict_analysis contient les fonctions nécessaires préalablement à un backtrack : 
  - backtrack_analysis : analyse la structure d'un clause (clause singleton, clause contenant un unique littéral assigné au niveau maximum...)
  - learn_clause : enregistre la clause donnée en argument et renvoie le type de backtrack à appliquer
  - conflict_analysis : analyse un conflit (provenant de DPLL) et renvoie  : la clause à ajouter, le littéral de plus niveau et le niveau auquel backtracker
