Base_smt:
=========

Un module de type Base_smt décrit une théorie. Il fournit des fonctions pour initialiser et maintenir à jour un état en cohérence avec le SAT-solveur.

Smt:
====

Le module Smt fournit un foncteur qui étant donné un algorithme construit par Algo_parametric et une 
théorie les articule en un solveur pour la théorie. Après avoir initialisé le SAT-solveur et les 
structures de la théorie, il les fait communiquer :

- Le SAT-solveur tente de parier sur un litéral selon son heuristique :
  
  - S'il n'y a plus de paris possibles, la formule est satisfiable du point de vue de DPLL, il faut
    alors vérifier la consistance des assignations par la théorie pour confirmer ou relancer un backtrack
    apprenant une clause expliquant le conflit.

  - Si un pari est possible il est effectué et DPLL effectue une propagation. Ces assignations sont
    alors enregistrées par la théorie. Périodiquement la théorie vérifie la consistance de l'état courant
    et peut demander à DPLL d'apprendre une clause et de backtracker. Sinon DPLL peut continuer son 
    exécution.

  - Si DPLL rencontre un conflit la théorie enregistre les assignations annulées et l'exécution de DPLL
    est relancée.

Vérification de la consistance:
-------------------------------

SMT peut gérer la vérification de la consistance de manière paresseuse. Quand DPLL communique une liste 
de modifications effectuées, elles sont enregistrées mais pas forcément répercutées dans la théorie.

Périodiquement ces modifications sont prises en compte et la consistance de la théorie est vérifiée.
Si un conflit est trouvé la théorie doit fournir une clause expliquant le conflit à DPLL pour qu'elle
soit apprise et que DPLL déclenche un backtrack.

Si un conflit est trouvé par DPLL et que des modifications sont en attente, le solveur SMT retire
les modifications pas encore répercutées mais déjà annulées dans DPLL de la liste d'attente et
annule le reste dans la théorie pour rester synchronisé avec DPLL. 