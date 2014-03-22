BUILD = src/_build
CC = ocamlbuild -I src -libs unix -build-dir $(BUILD)

all: generator solver

generator:
	$(CC) src/gen/gen.native; cp $(BUILD)/src/gen/gen.native gen
solver:
	$(CC) src/main.native; cp $(BUILD)/src/main.native main
debug:
	$(CC) -yaccflag -v main.d.byte
clean:
	$(CC) -clean
