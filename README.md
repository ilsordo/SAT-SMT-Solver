Projet2
=======

 #####################################################
 # 											 										         #
 #	 PROJET 2 : Rendu 1										 	         #
 #                                                   #
 #   Maxime Lesourd      										         #
 #	 Yassine HAMOUDI						 						         #
 #                                                   #
 #   Dépôt Git : https://github.com/nagaaym/projet2  #
 #											 										         #
 #####################################################
 #											 										         #
 #	 SOMMAIRE								 								         #
 #											 										         #
 #	 0 - Compilation et exécution				 		         #
 #	 1 - Structures de données					 		         #
 #	 1 - Prétraitement de l'entrée			 		         #
 #	 2 - Algorithmes                				         #
 #	 3 - Réponse à la partie 2	 						         #      
 #	 4 - Performances         	 						         #
 #	 4 - Optimisations         	 						         #
 #	 5 - Répartition des tâches	 						         #
 #											 										         #	
 #####################################################






%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    0 - Compilation et exécution    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


Pour compiler, entrer : 

						make


Pour exécuter le programme sur un fichier ex.cnf, entrer : 

						./resol ex.cnf


Pour accéler l'exécution du programme en effectuant un "nettoyage des seaux" (cf paragraphe 2), ajouter l'option "-clean" : 

						./resol ex.cnf -clean


Pour exécuter le programme sur un des fichiers contenus dans le dossier tests (ex1.cnf par exemple), entrer :

						./resol tests/ex1.cnf


Le programme affiche le résultat dans la console. Pour enregistrer ce résultat dans un fichier res.txt par exemple, entrer : 

						./resol tests/ex1.cnf > res.txt




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    1 - Structures de données    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


Les structures suivantes sont définies dans le fichier "formule.ml" : 

* Variable : une variable est un objet contenant une unique valeur : son nom (qui est un entier)

* VarSet : le module Set est utilisé pour définir des ensembles de variables

* Clause : une clause est un objet qui contient 2 valeurs : 
							- vpos : l'ensemble des variables (représenté par un VarSet) apparaissant positivement dans la clause 
							- vneg : l'ensemble des variables (représenté par un VarSet) apparaissant négativement dans la clause
					 Par exemple, pour la clause {x1 ou x2 ou (non x3)}, on a vpos=(x1,x2) et vneg=(x3)

* ClauseSet : le module Set est utilisé pour définir des ensembles de clauses

* Formule : une formule est un objet qui contient 4 valeurs :
							- nb_var : le nombre de variables apparaissant dans la formule
							- var : un tableau de taille nb_var dont la ième case contient la ième variable
							- valeur : un tableau de taille nb_var dont la ième case permet de stocker une affectation de la ième variable (0 si faux, 1 si vrai)
							- clau : l'ensemble des clauses de la formule, représenté par un ClauseSet


La structure suivante est définie dans le fichier "seaux.ml" : 

* Seaux : un seaux est un objet qui contient 3 valeurs : 
						 - nb_var : le nombre de variable figurant dans la formule associée au seau
						 - cpos : un tableau de taille nb_var dont la ième case contient l'ensemble des clauses où xi apparait positivement et est la plus grande variable
						 - cneg : un tableau de taille nb_var dont la ième case contient l'ensemble des clauses où xi apparait négativement et est la plus grande variable
						



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    2 - Algorithmes et optimisations    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


Le programme utilise l'algorithme de Davis-Putnam pour répondre au problème. 

Il a été remarqué que lors de la manipulation des seaux, de très nombreuses clauses "inutiles" (au sens où l'information qu'elles portent est redondante) sont engendrées. Si ces clause ne sont pas repérées et supprimées à temps, l'algorithme ne trouve pas de réponse en temps raisonnable au fichier ex1.cnf par exemple. 
Les 2 pratiques suivantes sont suivies par défaut : 

	- un ensemble de clause (ClauseSet) ne peut pas contenir deux clauses identiques (cf la fonction "compare" figurant dans le module "OrderedClause" dans le fichier "formule.ml")
	- lorsqu'une clause est ajoutée à un seau, on s'assure qu'il ne s'agit pas d'une tautologie ou d'une clause vide (cf "method add_c" figurant dans le fichier "seaux.ml")

Pour obtenir une réponse en temps raisonnable sur le fichier ex1.cnf par exemple, il est nécessaire d'effectuer en plus l'action suivante : 

	- les seaux sont "nettoyés" régulièrement : on repère tous les couples de clauses (c1,c2) où c1 contient c2 et on supprime c1 (cf "method nettoie_seaux" figurant dans le fichier "seaux.ml")

Cette dernière technique n'est pas activée par défaut (elle ne figure pas dans l'algorithme de Davis-Putnam). Lors de l'appel du programme sur un fichier ex.cnf, il faut ajouter l'option "-clean" pour l'activer : 

						./resol ex.cnf -clean




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    3 - Réponse à la partie 2    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


Il s'agit d'expliquer, dans le cas où une formule f est satisfiable, comment trouver une affectation des variables en témoignant.

(la démarche à suivre a été implémentée dans la fonction "affecter" figurant dans le fichier "seau.ml")

Considérons une formule f satisfiable, constituée des variables x1...xk.
On applique l'algorithme de Davis-Putnam à f, de sorte à remplir k seaux S1...Sk.
On déduit une affectation pour chaque variable de la manière suivante : 

	- si le seau S1 contient des clauses où figure le littéral x1, alors on effectue l'affectation (x1=vrai)
	- sinon (S1 contient des clauses où figure le littéral non x1, ou S1 est vide), alors on effectue l'affectation (x1=faux)

	- si le seau S2 ne contient pas de clauses où le littéral non x2 apparait, alors on effectue l'affectation (x2=vrai)
	- si le seau S2 ne contient pas de clauses où le littéral x2 apparait, ou si S2 est vide, alors on effectue l'affectation (x2=faux)
	- sinon, on parcours les clauses de S2 jusqu'à en trouver une qui ne puisse pas être satisfaite grâce à l'affectation de x1 effectuée précédemment :
			* si on ne trouve pas de telle clause, alors on effectue l'affectation (x2=faux)
			* si on trouve une telle clause, où le littéral x2 apparait, alors on effectue l'affectation (x2=vrai)
			* si on trouve une telle clause, où le littéral non x2 apparait, alors on effectue l'affectation (x2=faux)

	.... on remonte ainsi les seaux

	- si le seau Si (2<=i<=k) ne contient pas de clauses où le littéral non xi apparait, alors on effectue l'affectation (xi=vrai)
	- si le seau Si ne contient pas de clauses où le littéral xi apparait, ou si Si est vide, alors on effectue l'affectation (xi=faux)
	- sinon, on parcours les clauses de Si jusqu'à en trouver une qui ne puisse pas être satisfaite grâce aux affectations de x1,x2...x(i-1) effectuées précédemment :
			* si on ne trouve pas de telle clause, alors on effectue l'affectation (xi=faux)
			* si on trouve une telle clause, où le littéral xi apparait, alors on effectue l'affectation (xi=vrai)
			* si on trouve une telle clause, où le littéral non xi apparait, alors on effectue l'affectation (xi=faux)

	... on poursuit jusqu'au seau Sk

A la fin de cette procédure, on a bien construit une affectation des variables qui rend la formule f vraie.




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    4 - Réponse à la partie 4 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


Un générateur de formules aléatoires a été implémenté afin de tester les temps d'exécution du programme sur différentes entrées.

Ce générateur figure dans le dossier tests/generateur. Un fichier README.txt présent dans ce dossier explique comment l'utiliser. 
Le principe de fonctionnement de ce générateur est décrit ci-dessous : 

Le générateur prend en entrée un entier k :
	- k variables x1...xk sont créées
	- 4*k clauses comportant chacune 3 littéraux sont construites. Une clause est définie de la façon suivante :
			* trois variables sont tirées au hasards (parmis les variables précédemment créées) : y1,y2,y3
			* pour chaque variable yi, un booléen est tiré au hasard. S'il s'agit de vrai on ajoute le littéral yi à la clause, sinon on ajoute (non yi)


### Justification du choix de cet algorithme ###

Il est souhaitable qu'un algorithme générant des formules aléatoires remplisse les deux conditions suivantes : 
		1/ il est possible de contrôler la taille (nombre de variables, nombre de clauses, nombre de variables par clauses) des formules générées
	 	2/ les formules générées ne sont pas majoritairement satisfiable, ou majoritairement insatisfiables
Dans l'algorithme considéré ici, le point 1/ est respecté (on engendre k variables et 4*k clauses de taille 3 chacune). Le point 2/ est plus difficile à mettre en place. Le choix qui a été fait ici est motivé par les remarques suivantes : 
		* pour un nombre fixé de variables : plus il y a de clauses, plus la formule a de chances d'être insatisfiable (chaque clause ajoutée est une contrainte en plus).
		* à l'inverse, moins il y a de clauses, plus la formule a de chance d'être satisfiable et plus il va exister d'affectation en témoignant
		* de même, plus une clause est grande, plus elle a de chance d'être satisfiable.
En engendrant 4*k clauses de taille 3 pour k variables, on espère éviter les "déséquilibres" précedemment évoqués. A l'usage, on remarque effectivement que les formules produites sont "intéressantes", c'est-à-dire se répartissent plus ou moins équitablement entre formules satisfiables et formules insatisfiables.


### Analyse des performances du programme ###

Le temps d'exécution du programme a été enregistré sur différentes entrées aléatoires.
Ci-dessous figurent sur chaque ligne un nombre de variables, puis différents temps d'exécution observés sur plusieurs formules générées avec ce nombre de variables : 

Sans option "-clean" : 

5 : 0.003s, 0.001s
10 : 0.018s, 0.064s
15 : 5.518s, 5.286s
20 : out of memory (après 1min53s), out of memory

Avec option "-clean" :

5 : 0.030s, 0.002s
10 : 0.004s, 0.005s
20 : 0.106s, 0.043s, 0.055s
30 : 2.273s, 0.783s, 10.554s, 0.677s, 5.368s
35 : 19.595s, 9.843s, 2m49.872s, 1.875s, out of memory (après 4min8s)
40 : out of memory

L'option "-clean" permet donc de doubler le nombre de variables dans les formules générées.







