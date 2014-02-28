 #############################################
 # 											 										 #
 #	 Générateur de formules SAT						 	 #
 #											 										 #
 #	 Yassine HAMOUDI						 						 #
 #											 										 #
 #############################################


Le programme joint permet de générer des formules SAT aléatoires, à partir d'un paramètre k donné en entrée.
Des informations complémentaires figurent dans le fichier README.txt situé dans le répertoire parent.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Compilation et exécution    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


Pour compiler, entrer : 

						make


Pour générer une formule SAT de paramètre k, entrer : 

						./generer k


Pour générer une formule SAT de paramètre k et l'enregistrer dans un fichier ex.cnf par exemple, entrer : 

						./generer k > res.cnf


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Principe de fonctionnement    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Le générateur prend en entrée un entier k :
	- k variables x1...xk sont créées
	- 4*k clauses comportant chacune 3 littéraux sont construites. Une clause est définie de la façon suivante :
			* trois variables sont tirées au hasards (parmis les variables précédemment créées) : y1,y2,y3
			* pour chaque variable yi, un booléen est tiré au hasard. S'il s'agit de vrai on ajoute le littéral yi à la clause, sinon on ajoute (non yi)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Fichiers exemples    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Quelques formules produites par le générateur figurent dans le dossier parent. Les fichiers "aleak.cnf" (où k est un entier) contiennent une formule aléatoire à k variables.



