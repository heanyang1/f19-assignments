module NFS.Server

(* NFS* — skeleton for the CS242 final project, ported to modern F*
   (2026.03.24, installed via `opam install fstar z3`; build with `make`,
   run the given tests with `make test`).

   What is GIVEN (and verified): the basic types, the server state, user
   management, the security-policy pattern (file existence and per-user
   permission, stated as pre-conditions on the internal createFile' /
   openInternal functions and checked at runtime by their public wrappers),
   and the MOUNT and OPEN operations.

   YOUR JOB: implement the remaining operations listed at the bottom of this
   file (CLOSE, READ, WRITE, REMOVE, LOOKUP, LOOKUPP, READDIR, ACCESS and
   SETATTR), and design the specification for enforcing *user group*
   permissions (groups are flat: only users can be members, a user can be in
   several groups at once, and both OPEN/CREATE/SETATTR may be given a user
   or a group identity). Extend `system_state` and the policies as needed.

   Porting notes (vs. the 2019 starter): FStar.OrdMap/FStar.OrdSet no longer
   exist, so the state is modeled with concrete association lists and integer
   counters; the generic list helpers below (list_lookup, list_bind, ...)
   replace the OrdMap/OrdSet library. Everything else follows the original
   starter: internal `*'` helpers carry security policies as pre-conditions,
   and public wrappers check them at runtime (raising Failure), so F*
   statically guarantees the cores are never called in a violating state.
*)

open FStar.All
open FStar.List.Tot

(** Define the basic types in the system. **)
type id = int

type user_id = id

type file_id = int

type file_name = string

type file_path = list file_name

type data = string

type file_handle = int

type is_dir = bool

type permission =
  | Open
  | Read
  | Write
  | AttrModify

(** The server state.

    [file_permissions] maps each file id to a grant list: a list of
    (user, permissions) pairs. Ownership is modeled by grants: the creator
    (and the root superuser, id 0) receive every permission at creation time.

    Hint: to support groups you will likely want to add a table of groups
    (group id -> member users), a per-file group-grant table, and new
    policies reasoning about membership. *)
noeq type system_state = {
  users : list user_id;
  next_file_id : file_id;
  next_handle : file_handle;
  file_paths : list (file_id * (file_path * is_dir));
  file_contents : list (file_id * data);
  file_permissions : list (file_id * list (user_id * list permission));
  file_handles : list (file_handle * (file_id * user_id));
}

private let getFreshSystemState () : system_state = {
  users = [];
  next_file_id = 0;
  next_handle = 0;
  file_paths = [];
  file_contents = [];
  file_permissions = [];
  file_handles = [];
}

(* The global server state. (Effectful top-level binding; the warning is
   suppressed — this extracts to a normal OCaml ref allocated at load.) *)
#push-options "--warn_error -272"
private let system : ref system_state = ST.alloc (getFreshSystemState ())
#pop-options

(** ===== Generic association-list helpers =====
 * These replace the OrdMap/OrdSet library used by the 2019 starter. *)

private let rec list_lookup (#a : eqtype) (#b : Type) (l : list (a * b)) (x : a)
  : Tot (option b) =
  match l with
  | [] -> None
  | (k, v) :: tl -> if k = x then Some v else list_lookup tl x

(* Replace the entry for x, or append one if absent. *)
private let rec list_bind (#a : eqtype) (#b : Type) (l : list (a * b)) (x : a) (v : b)
  : Tot (list (a * b)) =
  match l with
  | [] -> [(x, v)]
  | (k, v0) :: tl -> if k = x then (x, v) :: tl else (k, v0) :: list_bind tl x v

private let rec list_unbind (#a : eqtype) (#b : Type) (l : list (a * b)) (x : a)
  : Tot (list (a * b)) =
  match l with
  | [] -> []
  | (k, v0) :: tl -> if k = x then tl else (k, v0) :: list_unbind tl x

private let rec list_contains (#a : eqtype) (l : list a) (x : a) : Tot bool =
  match l with
  | [] -> false
  | h :: tl -> if h = x then true else list_contains tl x

private let rec list_drop_val (#a : eqtype) (l : list a) (x : a) : Tot (list a) =
  match l with
  | [] -> []
  | h :: tl -> if h = x then list_drop_val tl x else h :: list_drop_val tl x

(* Is x present as the key of an association list? *)
private let rec list_has_key (#a : eqtype) (#b : Type) (l : list (a * b)) (x : a)
  : Tot bool =
  match l with
  | [] -> false
  | (k, _) :: tl -> if k = x then true else list_has_key tl x

(* Iterate an effectful action over a list (List.iter is ML-only). *)
private let rec iterAll (f : 'a -> All unit (requires (fun _ -> True))
                                   (ensures (fun _ _ _ -> True))) (l : list 'a)
  : All unit (requires (fun _ -> True)) (ensures (fun _ _ _ -> True)) =
  match l with
  | [] -> ()
  | h :: tl -> f h; iterAll f tl

(** ===== General helper functions ===== *)

(* Convert path into a string. *)
let pathToString (file_path : file_path) : Tot string =
  "/" ^ String.concat "/" file_path

(* Get file ID associated with the given path. *)
private let getFileId' (s : system_state) (file_path : file_path)
  : Tot (option file_id) =
  List.Tot.fold_left (fun acc entry ->
    match acc with
    | Some _ -> acc
    | None ->
      let (fid, pentry) = entry in
      let (p, _) = pentry in
      if p = file_path then Some fid else None)
    None s.file_paths

(** User operations. **)

val addUser : user_id -> ST unit
  (requires (fun h -> True)) (ensures (fun h x h' -> True))
let addUser user_id =
  if list_contains (!system).users user_id
  then ()
  else system := { !system with users = (!system).users @ [user_id] }

val removeUser : user_id -> ST unit
  (requires (fun h -> True)) (ensures (fun h x h' -> True))
let removeUser uid = system :=
  { !system with users = list_drop_val (!system).users uid }

val setUsers : list user_id -> ST unit
  (requires (fun h -> True)) (ensures (fun h x h' -> True))
let setUsers users = system := { !system with users = users }

val getUsers : unit -> ST (list user_id)
  (requires (fun h -> True)) (ensures (fun h x h' -> True))
let getUsers () = (!system).users

(** File operations (internal helpers). **)

(* Set attribute for user and file (internal): grant [permission] to
 * [user_id] on the file at [file_path], if the file exists. *)
private val setAttr : file_path -> user_id -> permission -> ST unit
  (requires (fun h -> True)) (ensures (fun h x h' -> True))
private let setAttr file_path user_id permission =
  match getFileId' !system file_path with
  | Some file_id ->
    let grants = match list_lookup (!system).file_permissions file_id with
      | Some g -> g
      | None -> []
    in
    let current = match list_lookup grants user_id with
      | Some ps -> ps
      | None -> []
    in
    let current =
      if list_contains current permission then current else current @ [permission]
    in
    system := { !system with
      file_permissions =
        list_bind (!system).file_permissions file_id (list_bind grants user_id current) }
  | None -> ()

(** Security policies.
 *
 * A policy is a boolean function of an abstract state; the `*_t` types turn
 * it into a proposition about a heap, usable as a pre-condition. F* then
 * statically verifies that the internal operations are only called when the
 * policy holds.
 *)

(* Policy that file exists. *)
private let fileExists (s : system_state) (f : file_path) : Tot bool =
  match getFileId' s f with
  | Some file_id ->
    list_has_key s.file_paths file_id &&
    list_has_key s.file_contents file_id &&
    list_has_key s.file_permissions file_id
  | None -> false

private type fileExists_t (f : file_path) (h : FStar.Heap.heap) =
  fileExists (Ref.sel h system) f == true

(* Policy that user has the given permission on the file path. *)
private let userHasPermission (s : system_state) (uid : user_id) (file_path : file_path)
  (permission : permission) : Tot bool =
  match getFileId' s file_path with
  | Some file_id ->
    begin
      match list_lookup s.file_permissions file_id with
      | Some grants ->
        begin
          match list_lookup grants uid with
          | Some ps -> list_contains ps permission
          | None -> false
        end
      | None -> false
    end
  | None -> false

private type userHasPermission_t (uid : user_id) (fp : file_path) (p : permission)
                                (h : FStar.Heap.heap) =
  userHasPermission (Ref.sel h system) uid fp p == true

(* Create file (internal).
 *
 * Requires that file does not already exist. *)
private val createFile' : (f : file_path) -> is_dir -> ST unit
  (requires (fun h -> ~(fileExists_t f h)))
  (ensures (fun h x h' -> True))
private let createFile' file_path is_dir =
  let file_id = (!system).next_file_id in
  let s = !system in
  system := { s with
    next_file_id = s.next_file_id + 1;
    file_paths = list_bind s.file_paths file_id (file_path, is_dir);
    file_contents = list_bind s.file_contents file_id "";
    file_permissions = list_bind s.file_permissions file_id [];
  }

(* Create file if it does not exist, then grant root and the creator every
 * permission on it. *)
private val createFile : file_path -> user_id -> is_dir -> All unit
  (requires (fun h -> True)) (ensures (fun h x h' -> True))
private let createFile file_path user_id is_dir =
  if fileExists !system file_path
  then failwith "file already exists"
  else createFile' file_path is_dir;
  let principals = if user_id = 0 then [0] else [0; user_id] in
  iterAll (fun uid ->
    iterAll (fun permission -> setAttr file_path uid permission)
      [Open; Read; Write; AttrModify]) principals

(* Open file (internal): bind the (fresh) handle to the file for the user.
 *
 * Requires: the user holds Open permission on the file path. *)
private val openInternal : (fh : file_handle) -> (uid : user_id) -> (fp : file_path) -> ST unit
  (requires (fun h -> userHasPermission_t uid fp Open h))
  (ensures (fun h x h' -> True))
private let openInternal fh uid file_path =
  match getFileId' !system file_path with
  | Some file_id ->
    system := { !system with
      next_handle = (!system).next_handle + 1;
      file_handles = list_bind (!system).file_handles fh (file_id, uid) }
  | None -> ()

(** Startup. **)

(* Called once to initialize the server: register the users, create the
 * virtual root directory (owned by root) and give every user Open
 * permission on it. *)
val startServer : list user_id -> All unit
  (requires (fun h -> True)) (ensures (fun h x h' -> True))
let startServer users =
  (* Reset server state. *)
  system := getFreshSystemState ();

  (* Create the root file object (dir), under root user. *)
  createFile [] 0 true;

  (* Create the root user (ID 0) and all other users. *)
  addUser 0;
  iterAll (fun user_id -> addUser user_id) users;

  (* Give all users permission to open root. *)
  iterAll (fun user_id -> setAttr [] user_id Open) users

(** Public operations. **)

(* MOUNT: mount the root directory for a user; returns the per-user root
 * file handle. *)
val nfsMount : user_id -> All file_handle
  (requires (fun h -> True)) (ensures (fun h x h' -> True))
let nfsMount user_id =
  let fh = (!system).next_handle in
  let root_file_path : file_path = [] in
  if userHasPermission !system user_id root_file_path Open
  then (openInternal fh user_id root_file_path; fh)
  else failwith "user does not have permission to mount"

(* OPEN: open (or create) the file [file_name] inside the directory referred
 * to by [parent_fh]; returns a fresh file handle. The handle must belong to
 * [id]; the parent must be a directory; creating requires that the file
 * does not exist (the creator is granted every permission); opening an
 * existing file requires Open permission on it. *)
val nfsOpen : file_handle -> file_name -> id -> bool -> All file_handle
  (requires (fun h -> True)) (ensures (fun h x h' -> True))
let nfsOpen parent_fh file_name id create_file =
  let parent_file_id = match list_lookup (!system).file_handles parent_fh with
    | Some (file_id, file_user_id) ->
      if id = file_user_id then file_id
      else failwith "OPEN: parent file handle does not belong to user"
    | None -> failwith "OPEN: parent file handle not found"
  in
  let parent_file_path = match list_lookup (!system).file_paths parent_file_id with
    | Some (file_path, is_dir) ->
      if is_dir then file_path
      else failwith "OPEN: parent file handle does not refer to directory"
    | None -> failwith "OPEN: parent file handle does not map to a valid path"
  in
  let file_path = parent_file_path @ [file_name] in
  if create_file then createFile file_path id false else ();
  let fh = (!system).next_handle in
  if userHasPermission !system id file_path Open
  then (openInternal fh id file_path; fh)
  else failwith "OPEN: user does not have permission to open file"

(** ===== Operations left to implement =====
 *
 * Implement each operation below, following the OPEN example: an internal
 * function carrying the relevant security policy as a pre-condition, plus a
 * public wrapper that checks the policy at runtime (failwith on violation)
 * before calling it. Suggested policies (see the assignment page):
 *
 * - CLOSE  fh uid            : the handle must belong to the user; drop the
 *                              binding (see list_unbind).
 * - READ   fh uid offset cnt : handle ownership + Read permission; return
 *                              the requested slice of the file contents.
 * - WRITE  fh uid offset buf : handle ownership + Write permission; splice
 *                              the data into the contents at offset.
 * - REMOVE fh uid            : handle ownership + Write permission; delete
 *                              the object's bookkeeping and its handle.
 * - LOOKUP  fh name uid      : handle ownership; parent must be a directory
 *                              and the child must exist; re-bind the handle
 *                              to the child.
 * - LOOKUPP fh uid           : handle ownership; re-bind the handle to the
 *                              parent of the current object.
 * - READDIR fh uid           : handle ownership + Read on the directory;
 *                              return the names of the contained objects.
 * - ACCESS  fh uid           : handle ownership; return the permissions the
 *                              user holds on the object.
 * - SETATTR fh uid ...       : handle ownership + AttrModify; grant/revoke
 *                              permissions for other users (or groups, once
 *                              you add group support).
 *
 * Extend the policies (fileExists / userHasPermission, or new ones) to cover
 * group permissions, and extend the test suite below to cover every
 * operation and the multi-user scenarios described on the assignment page.
 *)
