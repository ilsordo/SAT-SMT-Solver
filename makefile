all: 
	ocamlbuild -yaccflag -v -lib unix main.native
debug:
	ocamlbuild -yaccflag -v main.d.byte
clean: 
	ocamlbuild -clean
