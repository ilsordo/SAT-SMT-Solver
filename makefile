all: gen solver

gen:
	ocamlbuild gen.native; rm gen.native; cp _build/gen.native gen
solver:
	ocamlbuild -yaccflag -v main.native; rm main.native; cp _build/main.native main
debug:
	ocamlbuild -yaccflag -v main.d.byte
clean:
	ocamlbuild -clean
