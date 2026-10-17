# NFS* — modern F* (2026.03.24, installed via `opam install fstar z3`).
# The 2019 Makefile needed FSTAR_HOME pointing at an F* source tree; this one
# works against the opam-installed F* and its runtime library.

FSTAR      = fstar.exe
OCAMLOPT   = ocamlfind ocamlopt
PACKAGES   = zarith,batteries,stdint,ppx_deriving.std,ppx_deriving_yojson

# F*'s pre-compiled runtime modules (extracted code depends on these).
FSTAR_LIB  = $(shell ocamlfind query fstar)
APP        = $(FSTAR_LIB)/lib/app
RUNTIME_ML = Prims.ml FStar_Monotonic_Heap.ml FStar_CommonST.ml FStar_ST.ml \
             FStar_Pervasives_Native.ml FStar_UInt8.ml \
             ints/FStar_UInt16.ml ints/FStar_UInt32.ml ints/FStar_UInt64.ml \
             ints/FStar_Int8.ml ints/FStar_Int16.ml ints/FStar_Int32.ml \
             ints/FStar_Int64.ml FStar_Char.ml FStar_List_Tot_Base.ml \
             FStar_String.ml FStar_IO.ml

all: nfs_server nfs_server_test

# Re-check both modules with all security-policy obligations.
verify: NFS.Server.fst NFS.Server.Test.fst
	$(FSTAR) NFS.Server.fst NFS.Server.Test.fst

out:
	mkdir -p out

nfs_server: out NFS.Server.fst
	$(FSTAR) --codegen OCaml --extract 'NFS.Server' --odir out NFS.Server.fst
	cd out && $(OCAMLOPT) -package $(PACKAGES) -linkpkg -I $(APP) -I $(APP)/ints \
	  $(addprefix $(APP)/,$(RUNTIME_ML)) NFS_Server.ml -c

nfs_server_test: out NFS.Server.fst NFS.Server.Test.fst
	$(FSTAR) --codegen OCaml --extract 'NFS.Server' --extract 'NFS.Server.Test' \
	  --odir out NFS.Server.fst NFS.Server.Test.fst
	cd out && $(OCAMLOPT) -package $(PACKAGES) -linkpkg -I $(APP) -I $(APP)/ints \
	  $(addprefix $(APP)/,$(RUNTIME_ML)) NFS_Server.ml NFS_Server_Test.ml -o nfs_tests.exe

# Build (if needed) and run the test suite.
test: nfs_server_test
	./out/nfs_tests.exe

clean:
	rm -rf out *.exe

.PHONY: all verify test clean
