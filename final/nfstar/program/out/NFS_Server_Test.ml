open Prims
type all_unit = unit -> unit
let rassert (cond : Prims.bool) (failmsg : Prims.string) : unit=
  if cond then () else failwith failmsg
let rassert_exn (f : all_unit) (failmsg : Prims.string) : unit=
  let failed =
    try (fun uu___ -> match () with | () -> (f (); false)) ()
    with | uu___ -> true in
  rassert failed failmsg
let testUserOperations (uu___ : unit) : unit=
  NFS_Server.setUsers [];
  (let us0 = NFS_Server.getUsers () in
   rassert (us0 = []) "users not empty";
   NFS_Server.addUser Prims.int_one;
   (let us1 = NFS_Server.getUsers () in
    rassert (us1 = [Prims.int_one]) "users not 1";
    NFS_Server.addUser (Prims.of_int (2));
    (let us2 = NFS_Server.getUsers () in
     rassert (us2 = [Prims.int_one; (Prims.of_int (2))]) "users not 1,2";
     NFS_Server.addUser (Prims.of_int (3));
     (let us3 = NFS_Server.getUsers () in
      rassert (us3 = [Prims.int_one; (Prims.of_int (2)); (Prims.of_int (3))])
        "users not 1,2,3";
      NFS_Server.removeUser (Prims.of_int (2));
      (let us4 = NFS_Server.getUsers () in
       rassert (us4 = [Prims.int_one; (Prims.of_int (3))]) "users not 1,3";
       NFS_Server.removeUser (Prims.of_int (3));
       (let us5 = NFS_Server.getUsers () in
        rassert (us5 = [Prims.int_one]) "users not 1";
        NFS_Server.removeUser Prims.int_one;
        (let us6 = NFS_Server.getUsers () in
         rassert (us6 = []) "users not empty";
         NFS_Server.setUsers
           [Prims.int_one; (Prims.of_int (2)); (Prims.of_int (3))];
         (let us7 = NFS_Server.getUsers () in
          rassert
            (us7 = [Prims.int_one; (Prims.of_int (2)); (Prims.of_int (3))])
            "users not 1,2,3"))))))))
let testNfsOpen (uu___ : unit) : unit=
  let curr_fh = Prims.int_zero in
  let root1 = NFS_Server.nfsMount Prims.int_one in
  rassert (root1 = curr_fh) "root1 wrong";
  (let curr_fh1 = curr_fh + Prims.int_one in
   let root2 = NFS_Server.nfsMount (Prims.of_int (2)) in
   rassert (root2 = curr_fh1) "root2 wrong";
   (let curr_fh2 = curr_fh1 + Prims.int_one in
    let root3 = NFS_Server.nfsMount (Prims.of_int (3)) in
    rassert (root3 = curr_fh2) "root3 wrong";
    (let curr_fh3 = curr_fh2 + Prims.int_one in
     rassert_exn
       (fun uu___5 ->
          let uu___6 = NFS_Server.nfsMount (Prims.of_int (100)) in ())
       "non-existent user mount";
     rassert_exn
       (fun uu___6 ->
          let uu___7 =
            NFS_Server.nfsOpen (Prims.of_int (100)) "foo" Prims.int_zero true in
          ()) "bad parent file handle";
     rassert_exn
       (fun uu___7 ->
          let uu___8 = NFS_Server.nfsOpen root2 "foo" Prims.int_one true in
          ()) "parent file handle does not belong to user";
     rassert_exn
       (fun uu___8 ->
          let uu___9 = NFS_Server.nfsOpen root1 "foo" Prims.int_one false in
          ()) "file does not exist";
     (let uu___9 =
        let uu___10 = NFS_Server.nfsOpen root1 "foo" Prims.int_one true in
        uu___10 = curr_fh3 in
      rassert uu___9 "/foo cannot be opened by root1");
     (let curr_fh4 = curr_fh3 + Prims.int_one in
      (let uu___10 =
         let uu___11 = NFS_Server.nfsOpen root2 "bar" (Prims.of_int (2)) true in
         uu___11 = curr_fh4 in
       rassert uu___10 "/bar cannot be opened by root2");
      (let curr_fh5 = curr_fh4 + Prims.int_one in
       rassert_exn
         (fun uu___11 ->
            let uu___12 = NFS_Server.nfsOpen root1 "foo" Prims.int_one true in
            ()) "same file created twice";
       (let uu___12 =
          let uu___13 = NFS_Server.nfsOpen root1 "foo" Prims.int_one false in
          uu___13 = curr_fh5 in
        rassert uu___12 "/foo cannot be opened by root1");
       rassert_exn
         (fun uu___13 ->
            let uu___14 =
              NFS_Server.nfsOpen root2 "foo" (Prims.of_int (2)) false in
            ())
         "/foo was opened by user 2 that does not have permission to open")))))
let tests : all_unit Prims.list= [testUserOperations; testNfsOpen]
let rec iterTests (l : all_unit Prims.list) : unit=
  match l with | [] -> () | t::tl -> (t (); iterTests tl)
let runTests (uu___ : unit) : unit=
  let system_users =
    [Prims.int_one;
    (Prims.of_int (2));
    (Prims.of_int (3));
    (Prims.of_int (4));
    (Prims.of_int (5));
    (Prims.of_int (6));
    (Prims.of_int (7));
    (Prims.of_int (8));
    (Prims.of_int (9));
    (Prims.of_int (10))] in
  let rec run_all l =
    match l with
    | [] -> ()
    | t::tl -> (NFS_Server.startServer system_users; t (); run_all tl) in
  run_all tests
let main : unit= runTests (); FStar_IO.print_string "Tests Passed!\n"
