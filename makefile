INCLUDE = tseitin
CC = ocamlbuild -Is $(INCLUDE)

all: generator solver

generator:
	$(CC) gen.native; rm gen.native; cp _build/gen.native gen
solver:
	$(CC) -yaccflag -v main.native; rm main.native; cp _build/main.native main
debug:
	$(CC) -yaccflag -v main.d.byte
clean:
	$(CC) -clean
