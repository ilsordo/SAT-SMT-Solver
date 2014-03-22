Je pense que l'outil est bien utilisable maintenant. 
Il faudra voir pour tseitin et color comment on fait (cmt générer des tests, quoi mesurer...).
Il reste aussi à déterminer des tests pertinent : 
  - pour du 3-sat, les tests avec nb_clauses=4.3*nb_variables sont intéressants
  - ...

------------

TUTO :
  
Dans un fichier "tests.txt" (ou tout autre nom de fichier...) : 

  il faut décrire une batterie de tests qui donnera lieu à 1 graphe
  
  syntaxe à respecter : 
    - première ligne : NB_ALGOS = nombre d'algos (avec heur) qui vont être utilisé
    - NB_ALGOS lignes suivantes : un algo + une heur par ligne (tout écrit en majuscule et séparé par un espace)
    - ligne suivante : NB_PASSAGES NB_TESTS : 2 nbs séparés par un espace
      - NB_PASSAGES = nombre de fois que chaque test sera répété (pour avoir une moyenne)
      - NB_TESTS : nbs de tests qui vont avoir lieu
    - NB_TESTS lignes suivantes : un test par ligne = trois entiers n l k, séparés par un espace
    - 
  exemple (3 algos, 4 tests, chaque test répété 5 fois) : 
    3
    WL NEXT_RAND
    DPLL NEXT_RAND
    WL MOMS
    4 5
    100 3 400
    120 3 480
    140 3 560
    160 3 640
  
On lance ensuite dans un terminal : 
   bash run_tests.sh < tests.txt
   
Un fichier "donnees.dat" est généré (il est compréhensible par un humain...).

Pour avoir le graphe : 
   gnuplot -persist plot.p


-----------

Pas besoins de toucher à run_tests.sh (qui permet d'avoir donnees.dat) et plop.p (qui permet d'avoir le graphe). Pour avoir un pdf, il y a juste 1 ligne à décommenter dans plop.p


----------

Un exemple : 
  - j'ai renseigné le fichier test.txt
  - j'ai généré donnees.dat
  - on peut voir un joli graphe avec "gnuplot -persist plot.p"
  - on voit la puissance de MOMS :)
  
