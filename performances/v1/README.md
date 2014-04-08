#   Performances


******************************************************************************

1. Introduction
2. Effectuer et enregistrer des tests
3. Manipuler des résultats

******************************************************************************

 

1. Introduction
===============

Le fichier actuel décrit la procédure d'utilisation de la première version de nos scripts de tests. La dernière version gère en plus Tseitin et Colorie, elle est située dans le dossier parent.

L'ensemble des scripts et bases de données dont il est fait référence ci-dessous figurent dans le dossier v1.

L'ensemble des commandes détaillées paragraphes 2 et 3 nécessite le préchargement des outils ruby mis en place, et doivent être tapées au sein de pry. Pour effectuer ces tâches préalables, se placer à la racine du projet et entrer : 

    ./run_tests_v1.rb 
    
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
    
Le traitement des données se fait en définissant un filtre à l'aide de la commande select_data. La syntaxe est la suivante :

    filtre = select_data(n,l,k,algos,heurs,min_count) { |p,r| [série, paramètre, valeur] }
    
 * n, l et k correspondent respectivement au nombre de variables, à la longueur des clauses et au nombre de clauses. algos et heurs décrivent les algorithmes et heuristiques choisies. min_count est le nombre de résultats minimum à avoir pour afficher un point (ceci permet de ne pas afficher les mesures ayant provoqué de nombreux timeout)
 * pour définir les données précédentes, il est possible d'utiliser la syntaxe suivante : 
    *  Une constante pour ne garder qu'une valeur
    *  Un tableau [ a, b, ... , c ]
    *  Un intervalle (debut..fin)
    
Indiquer les titres pour les axes et le graphe grâce à la commande : 

    name = {:title => "Ici, le titre", :xlabel=>"Ici, l'axe x", :ylabel => "Ici, l'axe y"}
    
Afficher le graphe : 

    b.to_gnuplot filter,"stats_script/skel.p",name
    
Remarques : 
  * il est conseillé d'afficher les graphes obtenus en plein écran, et de cliquer sur "Apply autoscale" dans la fenêtre gnuplot pour un affichage optimal
  * il est possible de modifier le fichier "skel.p" pour enregistrer dans un fichier pdf le graphe obtenu
  * les filtres et name utilisés pour construire les courbes 1 à 7 figurent dans le fichier extraction.txt
    
