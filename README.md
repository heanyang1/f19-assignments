# The (Unofficial) Solution of Stanford CS242 19fall Assignments

[Course website](https://stanford-cs242.github.io/f19/)

## OCaml code

I have ported most OCaml code to OCaml 5.x, so **don't follow the instructions in the course's lab 1!** Instead, follow [the official guide](https://ocaml.org/docs/installing-ocaml) to install OCaml 5, then install all packages into your switch:
```sh
opam install core core_unix menhir utop merlin ocp-indent user-setup -y
```

The original assignment uses `corebuild`, which is obsolete and replaced by [dune](https://ocaml.org/p/dune/latest). Run `dune build` in the `assignX/program[/ocaml]` folder to compile the code.

## Useful Materials

### Assignment 2

[Jim Weirich: Adventures in Functional Programming](https://vimeo.com/45140590): introduces how to use fixpoint to write recursive functions

### Assignment 3

[OCaml Core documentation](https://v3.ocaml.org/p/core/latest/doc/index.html)

### Assignment 4

I gave up writing this assignment in OCaml and [rewritten it in Rust](https://github.com/heanyang1/interpreter).
