INCLUDE = tseitin

all: generator solver

generator:
	ocamlbuild -Is $(INCLUDE) gen.native; rm gen.native; cp _build/gen.native gen
solver:
	ocamlbuild $(INCLUDE) -yaccflag -v main.native; rm main.native; cp _build/main.native main
debug:
	ocamlbuild $(INCLUDE) -yaccflag -v main.d.byte
clean:
	ocamlbuild $(INCLUDE) -clean
