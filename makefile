all: 
	ocamlbuild -yaccflag -v -lib unix main.native; ln -fs main.native resol
debug:
	ocamlbuild -yaccflag -v main.d.byte
byte: 
	ocamlbuild -yaccflag -v main.byte
clean: 
	ocamlbuild -clean
