#   Performances


******************************************************************************

1. Introduction
2. Effectuer et enregistrer des tests
3. Manipuler des résultats

******************************************************************************

 

1. Introduction
===============

L'évaluation des performances se fait à 2 niveaux : 
  - au sein du code OCaml : différentes statistiques sont enregistrées et renvoyées à la fin de l'exécution du programme. Il s'agit de : 
      * nombre de conflits (provoquant un backtracking)
      * nombre de paris effectués
      * "Time (s)" : le temps utilisée pour résoudre la cnf donnée
      * "Reduction (s)" : le temps utilisé pour convertir le problème donné en entrée en une cnf (uniquement pour tseitin et colorie)
      * "Decision (heuristic) (s)" : le temps utilisé par les heuristiques pour décider sur quels littéraux parier

  - au sein d'un script Ruby chargé de :
      * lancer des tests
      * enregistrer dans des bases de données les résultats fournis par OCaml
      * permettre la manipulation des résultats obtenus (extraire des valeurs, tracer des courbes...)
  
Différents tests ont ainsi été menés afin d'obtenir les bases de données figurant dans le dossier performances/databases. Le fichier EXPERIENCE contient une analyse détaillée des courbes figurant dans le dossier performances/courbes, construites à partir des bases de données. Les scripts se trouvent dans performances/scripts.

Les paragraphes 2 et 3 ci-dessous détaillent la procédure d'utilisation des scripts Ruby. Il est nécessaire d'installer au préalable les outils suivants : 
  * ruby (version 1.9 minimum)
  * RubyGem (https://rubygems.org/)
  * pry (http://pryrepl.org/)

L'ensemble des commandes détaillées aux paragraphes 2 et 3 nécessitent le préchargement des outils ruby mis en place, et doivent être tapées au sein de pry. Pour effectuer ces tâches préalables, se placer à la racine du projet et entrer : 

    ./tests.rb 
    
L'utilisateur doit alors obtenir un invite de commande débutant par : 

    [1] pry(main)> 

Remarque :

Il a été nécessaire de réécrire une partie du code pour analyser colorie et tseitin, les tests pour resol sont dans le dossier performances/v1 avec les scripts utilisés pour les générer. Ces bases de données ne sont pas compatibles avec les nouveaux scripts, des bases de données correspondant aux mêmes tests peuvent être générées à partir de script.rb au nouveau format pour utiliser les outils décrits dans ce fichier.


2. Effectuer et enregistrer des tests
=====================================
La procédure d'exécution d'un test est :
  * Décrire le test souhaité dans le fichier script.rb. Les fonctions figurant dans le fichier exemples.rb permettent de se familiariser avec la syntaxe.
  * Exécuter les tests. Pour lancer 'test' avec enregistrement des résultats dans le fichier name.db (qui constitue la base de données) sur k threads il faut entrer la commande : 
    
    test("name.db", k)
        
La partie 3 ci-dessous explique comment utiliser une base de données (telle que name.db) pour construire des graphes.

A noter qu'un test (dans script.rb) peut également : 
  * charger une base de données existante et y ajouter des données.
  * afficher directement un graphe (voir exemple1 dans exemples.rb qui reprend les commandes d'extractions détaillées partie 3). Dans ce cas, on peut souhaiter ne pas enregistrer les données obtenues dans une base de données. C'est le cas de exemple1 qui s'exécute via la commande : 
   
    exemple1


3. Manipuler des résultats
==========================

Considérons une base de données name.db obtenue à partir des actions décrites paragraphe 2 (les bases de données que nous avons construites figurent dans le dossier performances/databases). On détaille ci-dessous les commandes permettant de la manipuler.

Il faut tout d'abord charger la base de données. Pour cela, entrer : 

    b = Database::new "name.db"
    
L'ensemble des données contenues dans le fichier défile dans la console (appuyer sur entrée pour défiler). Pour stopper le défilement, entrer : 

    q
    
Format des données :
--------------------

Les données sont stockées sous forme d'une table d'association dont la clé décrit une instance du problème et la valeur associée décrit le résultat. ( Note : au sein de la base de donnée on stocke la somme des résultats et le nombre d'instance qui ont été invoquées, de cette manière le programme peut automatiquement calculer la moyenne après sélection des résultats ). Si p correspond à une instance et r à un résultat on peut par exemple accéder à :

  * p[:n] : nombre de clauses d'une instance de SAT.
  * p[:algo] : algorithme utilisé (:heuristic pour l'heuristique).
  * r.count : nombre d'exécutions de l'instance.
  * r["Time (s)"] : temps d'exécution (on peut remplacer "Time (s)" par chacune des statistiques renvoyées en fin d'exécution de *resol*, par exemple "Conflits")
    
    
Création d'un filtre : 
----------------------

Le traitement des données se fait en définissant un filtre à l'aide de la commande select_data. La syntaxe est la suivante :

    filtre = select_data(contraintes,min_count) { |p,r| [série, paramètre, valeur] }
    
  * contraintes est une table d'association de la forme { :parametre => contrainte, ... } où contrainte peut être :
    *  Une constante pour ne garder qu'une valeur
    *  Un tableau [ a, b, ... , c ]
    *  Un intervalle (debut..fin)
  
Il est possible d'utiliser toutes les données présentées ci-dessus pour construire série, paramètre et valeur.

Remarque :
  Ces trois valeurs peuvent être des nombres ou des chaines de caractères sans espaces.
 
 
Affichage du graphe :
---------------------
Indiquer les titres pour les axes et le graphe grâce à la commande : 

    name = {:title => "Ici, le titre", :xlabel=>"Ici, l'axe x", :ylabel => "Ici, l'axe y"}
    
Afficher le graphe : 

    b.to_gnuplot filtre,name
    
Remarques : 
  * il est conseillé d'afficher les graphes obtenus en plein écran, et de cliquer sur "Apply autoscale" dans la fenêtre gnuplot pour un affichage optimal
  * il est possible de modifier le fichier "stats_script/skel.p" pour enregistrer dans un fichier pdf le graphe obtenu
    
    
