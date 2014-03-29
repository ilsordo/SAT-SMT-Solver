------------------
|   MiniScript   |
------------------

Les fichiers du présent dossier permettent de lancer automatiquement des batteries de tests sur les différents algorithmes et heuristiques.

Mode d'emploi
=============

Créer un fichier test.txt (par exemple), et décrire un ensemble de tests à l'intérieur (le format à respecter est décrit section suivante) :

Entrer dans le terminal :
  
   bash run_tests.sh < tests.txt
   
Un fichier "donnees.dat" est généré (il est compréhensible par un humain...).

Pour obtenir le graphe correspondant :
  
   gnuplot -persist plot.p

Le fichier run_tests.sh n'a pas à être modifié par l'utilisateur.
Il y a une ligne à décommenter dans plot.p pour enregistrer les graphes obtenus dans un fichier pdf.


Format des fichiers tests
=========================

Une batterie de tests (qui donnera lieu à 1 graphe) doit être décrite dans un fichier test.txt.

La syntaxe à respecter est la suivante :
    - première ligne : un entier NB_ALGOS correspondant aux nombres de couples (algorithme,heuristique) qui vont être utilisés dans le test
    - chacune des NB_ALGOS lignes suivante : le nom d'un algorithme puis, séparé par un espace, le nom d'une heuristique (le tout écrit en majuscule). Chaque ligne décrit ainsi un couple (algorithme,heuristique).
    - ligne suivante : deux entiers séparés par un espace : NB_PASSAGES et NB_TESTS
      - NB_PASSAGES : nombre de fois que chaque test sera répété (pour obtenir une moyenne)
      - NB_TESTS : nombre de tests qui vont avoir lieu
    - chacune des NB_TESTS lignes suivantes : un test par ligne, soit trois entiers n l k (ce qui correspond à une cnf de n variables, k clauses de longueur l)

Exemple (3 algos, 4 tests, chaque test est répété 5 fois) : 
    3
    WL NEXT_RAND
    DPLL NEXT_RAND
    WL MOMS
    4 5
    100 3 400
    120 3 480
    140 3 560
    160 3 640
  
Les algorithmes disponibles sont : 
  WL
  DPLL
  
Les heuristiques disponibles sont : 
  NEXT_RAND
  NEXT_MF
  RAND_RAND
  RAND_MF
  DLCS
  MOMS
  DLIS
  JEWA



Exemple
=======

Le dossier contient actuellment un exemple complet : 
  - le fichier test1.txt a été rempli avec un jeu de test
  - le fichier donnes.sat contient les temps d'exécution obtenus
  - le fichier courbe1.pdf contient le graphe correspondant
  
