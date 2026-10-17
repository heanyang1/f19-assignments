all: main.native
debug: main.byte

main.native: always
	dune build src/main.exe
	rm -f main.native && cp _build/default/src/main.exe main.native

main.byte: always
	dune build --profile dev src/main.exe
	rm -f main.byte && cp _build/default/src/main.exe main.byte

clean:
	dune clean
	rm -f main.native main.byte

always:

.PHONY: always
