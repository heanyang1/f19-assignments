open Core

let runtime_locals = ["s"; "src1"; "src2"; "n1"; "n2"; "n"; "dst"]

let rec translate_expr (e : Slang.expr) : Wasm.instr list =
  let open Wasm in
  match e with
  | Slang.String s ->
    let n : int = String.length s in
    let stores : instr list =
      String.to_list s
      |> List.mapi ~f:(fun (i : int) (c : char) ->
        [GetLocal "s"; Const i; Binop `Add;
         Const (Char.to_int c);
         Store])
      |> List.concat
    in
    [Const n; Call "alloc"; SetLocal "s"]
    @ stores @
    [GetLocal "s"; Const n]

  | Slang.Concat (e1, e2) ->
    let stores1 = translate_expr e1 in
    let stores2 = translate_expr e2 in
    stores1 @ stores2 @
    [
      SetLocal "n2"; SetLocal "src2"; SetLocal "n1"; SetLocal "src1";
      GetLocal "n1"; GetLocal "n2"; Binop `Add; SetLocal "n";
      GetLocal "n"; Call "alloc"; SetLocal "dst";
      GetLocal "src1"; GetLocal "dst"; GetLocal "n1"; Call "memcpy";
      GetLocal "src2"; GetLocal "dst"; GetLocal "n1"; Binop `Add; GetLocal "n2"; Call "memcpy";
      GetLocal "src1"; Call "dealloc";
      GetLocal "src2"; Call "dealloc";
      GetLocal "n"; GetLocal "dst";
    ]

  | Slang.Call (x, es) ->
    (List.concat (List.map ~f:translate_expr es))
    @ [Call x; GetGlobal "length"]

  | Slang.Var x ->
    [GetLocal x; GetLocal (x ^ "len")]

let translate_stmt
      ((gen, locals) : (Wasm.instr list) * (string list))
      (stmt : Slang.stmt)
  : (Wasm.instr list) * (string list)
  =
  let open Slang in
  match stmt with
  | Assign (x, e) ->
    (gen @ (translate_expr e) @ [SetLocal (x ^ "len"); SetLocal x],
     [x; x ^ "len"] @ locals)
  | Return e ->
    (gen @ (translate_expr e) @ [SetGlobal "length"; Wasm.Return], locals)

let translate_func (f : Slang.func) : Wasm.func =
  let (body, locals) =
    List.fold ~init:([], runtime_locals) ~f:translate_stmt f.body
  in
  {name = f.name;
   params = List.map f.params ~f:(fun x -> [x; x ^ "len"]) |> List.concat;
   body; locals}

let translate (p : Slang.prog) : Wasm.module_ =
  List.map ~f:translate_func p
