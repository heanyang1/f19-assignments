open Core
open Result.Monad_infix

type expr =
  | String of string
  | Concat of expr * expr
  | Var of string
  | Call of string * expr list

type stmt =
  | Assign of string * expr
  | Return of expr

type func = {name: string; params: string list; body: stmt list}

type prog = func list

let rec typecheck_expr
          (fn_map : string list String.Map.t)
          (var_set : String.Set.t)
          (e : expr)
  : (String.Set.t, string) Result.t =
  let tc = typecheck_expr fn_map in
  match e with
  | String _ -> Ok var_set

  | Concat (e1, e2) ->
    tc var_set e1 >>= fun new_var_set -> tc new_var_set e2

  | Var x ->
    if Set.mem var_set x then
      Ok (Set.remove var_set x)
    else
      Error (Printf.sprintf "Variable %s is undefined or moved" x)

  | Call (x, args) ->
    List.fold args ~init:(Ok var_set)
      ~f:(fun res arg ->
        res >>= fun new_var_set -> tc new_var_set arg)
    >>= fun new_var_set ->
    (match Map.find fn_map x with
     | Some expected_args ->
       if List.length expected_args = List.length args then Ok new_var_set
       else Error (Printf.sprintf
                     "List was given %d parameters, expected %d parameters"
                     (List.length expected_args) (List.length args))
     | None -> Error (Printf.sprintf "Called undefined function %s" x))

let typecheck_func (fn_map : string list String.Map.t) (f : func)
  : (String.Set.t, string) Result.t =
  List.fold f.body
    ~init:((Ok (String.Set.of_list f.params)))
    ~f:(fun var_set_res s ->
      var_set_res >>= fun var_set ->
      (match s with
       | Assign (x, e) ->
         typecheck_expr fn_map var_set e
         >>| fun new_var_set -> Set.add new_var_set x
       | Return e ->
         typecheck_expr fn_map var_set e))
  >>= fun end_var_set -> match Set.choose end_var_set with
   | None -> Ok String.Set.empty
   | Some x -> Error (Printf.sprintf "variable %s is unused" x)

let typecheck (p : prog) : (unit, string) Result.t =
  let fn_map =
    String.Map.of_alist_exn (List.map p ~f:(fun f -> (f.name, f.params)))
  in
  List.fold p
    ~init:(Ok ())
    ~f:(fun acc f -> acc >>= fun () -> typecheck_func fn_map f >>= fun end_var_set -> match Set.choose end_var_set with
    | None -> Ok ()
    | Some x -> Error (Printf.sprintf "variable %s is unused" x))
