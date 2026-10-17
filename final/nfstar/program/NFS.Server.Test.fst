module NFS.Server.Test

(* Given tests for the NFS* skeleton (modern FStar).
 *
 * These exercise the functionality that is already implemented (user
 * management, MOUNT, OPEN/CREATE). All given tests pass with the initial
 * starter code — extend this file with your own test suite as you implement
 * the remaining operations (READ, WRITE, CLOSE, REMOVE, LOOKUP, LOOKUPP,
 * READDIR, ACCESS, SETATTR) and the multi-user scenarios from the
 * assignment page (e.g. Alice creates a file and writes to it, Bob attempts
 * to read (fails), Alice grants Bob read permission, Bob reads (succeeds);
 * and the ROOT/Foo/Bar directory traversal).
 *)

open FStar.All
open FStar.Exn
open FStar.List.Tot

open NFS.Server

type all_unit = unit -> All unit (requires (fun h -> True)) (ensures (fun h x h' -> True))

(** Runtime assertions. **)

(* Assert that condition is true. *)
let rassert cond failmsg =
  if cond then () else failwith failmsg

(* Assert that exception occurred. *)
let rassert_exn (f : all_unit) failmsg =
  let failed = try (f (); false) with | _ -> true in
  rassert failed failmsg

(** Test user operations. **)

let testUserOperations () : All unit (requires (fun h -> True)) (ensures (fun h x h' -> True)) =
  (* Reset users for the tests. *)
  setUsers [];
  let us0 = getUsers () in
  rassert (us0 = []) "users not empty";

  (* Add users. *)
  addUser 1;
  let us1 = getUsers () in
  rassert (us1 = [1]) "users not 1";
  addUser 2;
  let us2 = getUsers () in
  rassert (us2 = [1; 2]) "users not 1,2";
  addUser 3;
  let us3 = getUsers () in
  rassert (us3 = [1; 2; 3]) "users not 1,2,3";

  (* Remove users. *)
  removeUser 2;
  let us4 = getUsers () in
  rassert (us4 = [1; 3]) "users not 1,3";
  removeUser 3;
  let us5 = getUsers () in
  rassert (us5 = [1]) "users not 1";
  removeUser 1;
  let us6 = getUsers () in
  rassert (us6 = []) "users not empty";

  (* Set users. *)
  setUsers [1; 2; 3];
  let us7 = getUsers () in
  rassert (us7 = [1; 2; 3]) "users not 1,2,3";

  ()

(** Test MOUNT and OPEN. **)

let testNfsOpen () : All unit (requires (fun h -> True)) (ensures (fun h x h' -> True)) =
  let curr_fh = 0 in

  (* Test mounting server. *)
  let root1 = nfsMount 1 in
  rassert (root1 = curr_fh) "root1 wrong";
  let curr_fh = curr_fh + 1 in
  let root2 = nfsMount 2 in
  rassert (root2 = curr_fh) "root2 wrong";
  let curr_fh = curr_fh + 1 in
  let root3 = nfsMount 3 in
  rassert (root3 = curr_fh) "root3 wrong";
  let curr_fh = curr_fh + 1 in

  (* Test that exceptions raised on bad inputs to nfsMount/nfsOpen. *)
  rassert_exn (fun () -> let _ = nfsMount 100 in ())
    "non-existent user mount";
  rassert_exn (fun () -> let _ = nfsOpen 100 "foo" 0 true in ())
    "bad parent file handle";
  rassert_exn (fun () -> let _ = nfsOpen root2 "foo" 1 true in ())
    "parent file handle does not belong to user";
  rassert_exn (fun () -> let _ = nfsOpen root1 "foo" 1 false in ())
    "file does not exist";

  (* Test no exceptions thrown on good inputs, correct handles are returned. *)
  rassert (nfsOpen root1 "foo" 1 true = curr_fh)
    "/foo cannot be opened by root1";
  let curr_fh = curr_fh + 1 in
  rassert (nfsOpen root2 "bar" 2 true = curr_fh)
    "/bar cannot be opened by root2";
  let curr_fh = curr_fh + 1 in

  (* Ensure duplicate files cannot be created. *)
  rassert_exn (fun () -> let _ = nfsOpen root1 "foo" 1 true in ())
    "same file created twice";

  (* Opening existing file (not creating), ensure we get a new handle back. *)
  rassert (nfsOpen root1 "foo" 1 false = curr_fh)
    "/foo cannot be opened by root1";

  (* Make sure user 2 cannot open user 1's file. *)
  rassert_exn (fun () -> let _ = nfsOpen root2 "foo" 2 false in ())
    "/foo was opened by user 2 that does not have permission to open";

  ()

(** Test runner. **)

let tests : list all_unit = [
  testUserOperations;
  testNfsOpen;
]

private let rec iterTests (l : list all_unit) : All unit (requires (fun _ -> True))
                                                      (ensures (fun _ _ _ -> True)) =
  match l with
  | [] -> ()
  | t :: tl -> t (); iterTests tl

let runTests () =
  let system_users : list user_id = [1; 2; 3; 4; 5; 6; 7; 8; 9; 10] in
  let rec run_all (l : list all_unit) : All unit (requires (fun _ -> True))
                                              (ensures (fun _ _ _ -> True)) =
    match l with
    | [] -> ()
    | t :: tl -> startServer system_users; t (); run_all tl
  in
  run_all tests

#push-options "--warn_error -272"
let main = runTests (); FStar.IO.print_string "Tests Passed!\n"
#pop-options
