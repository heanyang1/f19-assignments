# Stanford CS242 (Fall 2019) assignments — skeleton code, ported to run on a modern machine

> This branch is heavily modified by an AI agent. The changes to README.md is almost left as is. I think it's OK as long as I (or you) have to finish the assignment by yourself.

[Course website](https://stanford-cs242.github.io/f19/assignments)

This is the `skeleton` branch of the unofficial assignments repo, updated so
every assignment can be completed **on my machine in 2026** (CachyOS / Arch, OCaml
5.5, Rust 1.97, Node 26, Python 3.14, Lean via elan). The assignment code is
still skeleton code — all `raise Unimplemented` / `unimplemented!()` /
`todo!()` holes are yours to fill.

## Toolchain setup (one-time)

* **OCaml** — opam was initialized with the system compiler and a `default`
  switch:
  ```sh
  opam init          # already done
  opam switch create default ocaml-system   # already done
  opam install dune core core_unix ppx_let ppx_here ppx_jane menhir ocamlformat merlin
  ```
  Make sure your shell is opam-initialized (`eval $(opam env)`, which
  `opam init` added to `~/.bashrc`) before running `make`/`dune`.
* **Rust / Node / Python / LaTeX** — already present system-wide.
  `pygmentize` (needed by LaTeX `minted`) is installed at
  `~/.local/bin/pygmentize` (venv at `~/.local/venvs/pytools`).
* **Lean** — elan installs the pinned toolchain (`v4.19.0-rc2`) automatically.

## Per-assignment status

### assign4 — OCaml interpreter (ported)

Was ocamlbuild + Jane Street `corebuild`; now dune:
`make` builds `main.native`, `python3 run_tests.py` compares your interpreter
against the staff reference.

**The reference interpreter** (`reference.byte`) is OCaml 4.06-era bytecode
that a modern `ocamlrun` refuses to load (bytecode magic
`Caml1999X037` vs `Caml1999X011`). A compatible OCaml 4.06.1 runtime is
installed at `~/.local/ocaml406/` (built from source), together with the
dynamic stub libraries the reference needs
(`dllunix`, `dllthreads`, `dllbigarray`, plus the Jane Street 2019 stack:
`dllbase_stubs`, `dllbin_prot_stubs`, `dllcore_stubs`,
`dllcore_kernel_stubs`, `dllexpect_test_collector_stubs`,
`dllspawn_stubs` — rebuilt from the v0.11 sources). `reference.sh` picks
that runtime automatically. If it's ever missing, rebuild it by installing
OCaml 4.06.1 (`./configure` needs `CC="gcc -std=gnu11 -fcommon"`,
`HAS_GETCWD`/`SUPPORT_DYNAMIC_LINKING`/`HAS_IPV6` in `s.h`) and the
aforementioned stub libs.

**Core v0.17 API changes** applied to provided scaffolding (not to assignment
holes): polymorphic compare is gone from Core, so provided files `open Poly`
to keep the original `=` semantics; `Command.run` → `Command_unix.run`;
in `final/dlang` also `String.Map.add/find/...` → `Map.add/...`,
`List.zip` pattern `Some/None` → `Ok/Unequal_lengths`, `String.Set.length` →
`Set.length`. If *your* code hits “expected of type int” on a comparison,
`open Poly` (or use `Poly.equal`) restores the old behavior.

### assign5/6 — WebAssembly (webpack 4 → 5)

webpack-dev-server 3 can't run on Node ≥ 22 (`process.binding` removed), and
webpack 4's MD4 hashing needs the OpenSSL legacy provider. Both projects were
upgraded to webpack 5 / webpack-dev-server 4:

* `npm install` in the `wasm` dir (fresh lockfiles committed)
* `npm run build` to build, `npm start` for the live-testing page
* `.wat` files are loaded via webpack 5 asset modules (`buffer-loader` is gone)
* assign6 also instantiates `wasm-alloc`/`memcpy` via plain
  `fetch` + `WebAssembly.instantiate` (no `wasm-loader`)
* assign6 workflow: `dune exec src/main.exe` in `assign6/program/ocaml`
  writes `basic.wat`/`concat.wat`/`funcall.wat` into the wasm `src/` dir
  (these are generated — gitignored), then `npm start` in
  `assign6/program/wasm` to test them in the browser.

### final options

* **final/dlang** — ported to dune like assign4 (`make` in
  `final/dlang/program`). The pytest suite needs `pytest` and `torch`; the
  pinned `torch==1.3.1` is unbuildable today, but current torch works:
  ```sh
  python3 -m venv ~/.local/venvs/dlang
  ~/.local/venvs/dlang/bin/pip install pytest torch numpy
  cd final/dlang/program/tests && ~/.local/venvs/dlang/bin/pytest --compiler_bin main.native
  ```
* **final/lean** — Lean 4 + mathlib, pinned via `lean-toolchain` and
  `lake-manifest.json`. The mathlib prebuilt cache is already downloaded
  (`lake exe cache get` was run; re-run it if you update anything). Build
  modules with e.g. `lake build Final.arith`; create `Final.lean` to
  aggregate your imports for `lake build`.
* **final/rlu** — builds and tests fine with current Rust (`cargo test`).
* **final/nfstar** — *rewritten for modern F\** (2026.03.24, installed via
  `opam install fstar z3`; the `z3` package provides the exact Z3 version F*
  needs). The old code used `FStar.OrdMap`/`FStar.OrdSet`, which no longer
  exist, so the state is modeled with concrete association lists and integer
  counters instead. Both the implementation (`NFS.Server.fst`) and the test
  suite (`NFS.Server.Test.fst`) fully verify, extract to OCaml and pass:
  ```sh
  cd final/nfstar/program
  make verify   # F* checks all security-policy obligations
  make test     # builds nfs_tests.exe and runs the test suite
  ```
  All assignment operations are implemented: MOUNT, OPEN, CREATE (dir),
  CLOSE, READ, WRITE, REMOVE, LOOKUP, LOOKUPP, READDIR, ACCESS and SETATTR
  (user + flat-group ACLs; owner/root always hold every permission). The
  statically-enforced policies are: file-exists, user-exists, group-exists,
  handle-liveness, handle-ownership, per-permission authorization (direct
  user grant, group grant via membership, or owner/root), stated as
  pre-conditions on the internal `*'` cores that the public wrappers prove
  at each call site.

## Original notes

The (Unofficial) Solution of Stanford CS242 19fall Assignments.
The original author's solution code is on the `master` branch — avoid looking
at it while solving. Useful materials:

- Assignment 2: [Jim Weirich: Adventures in Functional Programming](https://vimeo.com/45140590): introduces how to use fixpoint to write recursive functions
- Assignment 3: [OCaml Core documentation](https://ocaml.org/p/core/latest/doc/index.html)
- Assignment 6: [Free access to the linear type paper](https://citeseerx.ist.psu.edu/document?repid=rep1&type=pdf&doi=24c850390fba27fc6f3241cb34ce7bc6f3765627)
