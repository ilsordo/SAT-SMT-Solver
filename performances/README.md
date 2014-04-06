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
  
Différents tests ont ainsi été menés afin d'obtenir les bases de données figurant dans le dossier .... Le fichier ... joint à celles-ci renseigne sur leur contenu. Le fichier EXPERIENCE contient quant à lui une analyse détaillée des courbes figurant dans le dossier "courbes", construites à partir des bases de données.

Les paragraphes 2 et 3 ci-dessous détaillent la procédure d'utilisation des scripts Ruby. Il est nécessaire d'installer au préalable les outils suivants : 
  * ruby (version 1.9 minimum)
  * RubyGem (https://rubygems.org/)
  * pry (http://pryrepl.org/)

L'ensemble des commandes détaillées paragraphes 2 et 3 nécessitent le préchargement des outils ruby mis en place, et doivent être tapées au sein de pry. Pour effectuer ces tâches préalables, se placer à la racine du projet et entrer : 

    ./test.rb 
    
L'utilisateur doit alors obtenir un invite de commande débutant par : 

    [1] pry(main)> 



2. Effectuer et enregistrer des tests
=====================================

La procédure d'exécution d'un test est :
  * indiquer dans le fichier base.rb, ligne 10, le nombre de coeurs que comporte le processeur de l'ordinateur. Par exemple, avec 4 coeurs il faut inscrire : "Threads = 4". Ceci permet d'exécuter plusieurs tests en parallèle en exploitant le multithreading
  * décrire le test souhaité dans le fichier script.rb. Le test main figurant au début du fichier permet de se familiariser avec la syntaxe.
  * exécuter les tests. Pour lancer main avec enregistrement des résultats dans le fichier name.db (qui constitue la base de données), entrer la commande : 
    
        main "name.db"
        
La partie 3 ci-dessous explique comment utiliser une base de données (telle que name.db) pour construire des graphes.

A noter qu'un test (dans script.rb) peut également : 
  * charger une base de données existante et y ajouter des données
  * afficher directement un graphe (voir exemple1 dans script.rb qui reprend les commandes d'extractions détaillées partie 3). Dans ce cas, on peut souhaiter ne pas enregistrer les données obtenues dans une base de données. C'est le cas de exemple1 qui s'exécute via la commande : 
   
        exemple1



3. Manipuler des résultats
==========================

Considérons une base de données name.db obtenue à partir des actions décrites paragraphe 2 (les bases de données que nous avons construites figurent dans le dossier ...). On détaille ci-dessous les commandes permettant de la manipuler.

Il faut tout d'abord charger la base de données. Pour cela, entrer : 

    b = Database::new "name.db"
    
L'ensemble des données contenues dans le fichier défile dans la console (appuyer sur entrée pour défiler). Pour stopper le défilement, entrer : 

    q
    
sélection des datas : 
  ...
    
Indiquer les titres pour les axes et le graphe grâce à la commande : 

    name = {:title => "Ici, le titre", :xlabel=>"Ici, l'axe x", :ylabel => "Ici, l'axe y"}
    
Afficher le graphe : 

    b.to_gnuplot l,"stats_script/skel.p",name
    
Remarques : 
  * il est conseillé d'afficher les graphes obtenus en plein écran, et de cliquer sur "Apply autoscale" dans la fenêtre gnuplot pour un affichage optimal
  * il est possible de modifier le fichier "skel.p" pour enregistrer dans un fichier pdf le graphe obtenu
    
    
