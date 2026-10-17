all: exercise1 exercise2

exercise1: always
	dune build
	rm -f exercise1 && cp ../_build/default/starter/exercise1.exe exercise1

exercise2: always
	dune build
	rm -f exercise2 && cp ../_build/default/starter/exercise2.exe exercise2

clean:
	dune clean
	rm -f exercise1 exercise2

always:

.PHONY: always
