# The (Unofficial) Solution of Stanford CS242 19fall Assignments

[Course website](https://stanford-cs242.github.io/f19/)

## Code

I ported some of the assignments and final project so that they can be done in newer environments.
- Most OCaml assignments are ported to OCaml 5 and `corebuild` is replaced by [dune](https://ocaml.org/p/dune/latest). Run `dune build` in the folder that has a `dune-project` file, then the compiled executable is at `_build/default/src/*.exe`.
- I gave up porting assignment 4 and rewritten it in Rust (at [here](https://github.com/heanyang1/interpreter), not in this repo).
- The theorem proving project is ported to [Lean 4](https://github.com/leanprover/lean4/). The lean programs are in the `final/lean/program/Final` folder.
- I also fixed some issues related to the WASM test framework.

I encourage you NOT to see my code and use the skeleton code to write your solution. The skeleton code is at the `skeleton` branch:
```sh
git checkout skeleton
```

## Useful Materials

- Assignment 2: [Jim Weirich: Adventures in Functional Programming](https://vimeo.com/45140590): introduces how to use fixpoint to write recursive functions
- Assignment 3: [OCaml Core documentation](https://ocaml.org/p/core/latest/doc/index.html)
- Assignment 6: [Free access to the linear type paper](https://citeseerx.ist.psu.edu/document?repid=rep1&type=pdf&doi=24c850390fba27fc6f3241cb34ce7bc6f3765627)
