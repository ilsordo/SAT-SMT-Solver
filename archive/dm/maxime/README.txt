Installation:
make

Usage:
./resol [fichier|-test1 n_vars|-test2 n_vars l_clause n_clause]

test1 n génère aléatoirement une instance de 3-SAT à n variables et 10n clauses.
test2 permet de controler le nombre de variables par clause et le nombre de clause.

Question 1)

Une fois que l'algorithme décide que l'instance possède une solution on peut trouver une
instanciation des variables convenable en remontant les seaux en sens inverse:
S'il y a des clauses avec des occurences positives de la k-ième variable dans son seau et que les
assignations déjà décidées ne suffisent pas à satisfaire ces clauses alors il faut et il suffit de
mettre la k-ième variable à vrai. Sinon on peut la mettre à faux.

Question 2)

On peut lancer test.sh k pour chronometrer une exécution de resol -test1 k  et la comparer au résultat de minisat
(note : il peut être nécessaire de changer le chemin vers minisat)

Expérimentalement la barre des 5 minutes est dépassée aux alentours de k = 11 ou 12
