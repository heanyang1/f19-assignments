#!/bin/bash
# reference.byte is OCaml 4.06-era bytecode (magic Caml1999X011); modern
# ocamlrun (5.x) cannot load it. It runs under the 4.06.1 runtime installed
# at ~/.local/ocaml406 (built from source; see README).
OCAMLRUN406="$HOME/.local/ocaml406/bin/ocamlrun"
DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -x "$OCAMLRUN406" ]; then
  exec "$OCAMLRUN406" "$DIR/reference.byte" "$@"
else
  exec ocamlrun "$DIR/reference.byte" "$@"
fi
