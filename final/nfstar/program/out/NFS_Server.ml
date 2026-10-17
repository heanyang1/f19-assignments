open Prims
type id = Prims.int
type user_id = id
type file_id = Prims.int
type file_name = Prims.string
type file_path = file_name Prims.list
type data = Prims.string
type file_handle = Prims.int
type is_dir = Prims.bool
type permission =
  | Open 
  | Read 
  | Write 
  | AttrModify 
let uu___is_Open (projectee : permission) : Prims.bool=
  match projectee with | Open -> true | uu___ -> false
let uu___is_Read (projectee : permission) : Prims.bool=
  match projectee with | Read -> true | uu___ -> false
let uu___is_Write (projectee : permission) : Prims.bool=
  match projectee with | Write -> true | uu___ -> false
let uu___is_AttrModify (projectee : permission) : Prims.bool=
  match projectee with | AttrModify -> true | uu___ -> false
type system_state =
  {
  users: user_id Prims.list ;
  next_file_id: file_id ;
  next_handle: file_handle ;
  file_paths: (file_id * (file_path * is_dir)) Prims.list ;
  file_contents: (file_id * data) Prims.list ;
  file_permissions:
    (file_id * (user_id * permission Prims.list) Prims.list) Prims.list ;
  file_handles: (file_handle * (file_id * user_id)) Prims.list }
let __proj__Mksystem_state__item__users (projectee : system_state) :
  user_id Prims.list=
  match projectee with
  | { users; next_file_id; next_handle; file_paths; file_contents;
      file_permissions; file_handles;_} -> users
let __proj__Mksystem_state__item__next_file_id (projectee : system_state) :
  file_id=
  match projectee with
  | { users; next_file_id; next_handle; file_paths; file_contents;
      file_permissions; file_handles;_} -> next_file_id
let __proj__Mksystem_state__item__next_handle (projectee : system_state) :
  file_handle=
  match projectee with
  | { users; next_file_id; next_handle; file_paths; file_contents;
      file_permissions; file_handles;_} -> next_handle
let __proj__Mksystem_state__item__file_paths (projectee : system_state) :
  (file_id * (file_path * is_dir)) Prims.list=
  match projectee with
  | { users; next_file_id; next_handle; file_paths; file_contents;
      file_permissions; file_handles;_} -> file_paths
let __proj__Mksystem_state__item__file_contents (projectee : system_state) :
  (file_id * data) Prims.list=
  match projectee with
  | { users; next_file_id; next_handle; file_paths; file_contents;
      file_permissions; file_handles;_} -> file_contents
let __proj__Mksystem_state__item__file_permissions (projectee : system_state)
  : (file_id * (user_id * permission Prims.list) Prims.list) Prims.list=
  match projectee with
  | { users; next_file_id; next_handle; file_paths; file_contents;
      file_permissions; file_handles;_} -> file_permissions
let __proj__Mksystem_state__item__file_handles (projectee : system_state) :
  (file_handle * (file_id * user_id)) Prims.list=
  match projectee with
  | { users; next_file_id; next_handle; file_paths; file_contents;
      file_permissions; file_handles;_} -> file_handles
let getFreshSystemState (uu___ : unit) : system_state=
  {
    users = [];
    next_file_id = Prims.int_zero;
    next_handle = Prims.int_zero;
    file_paths = [];
    file_contents = [];
    file_permissions = [];
    file_handles = []
  }
let system : system_state FStar_ST.ref=
  FStar_ST.alloc (getFreshSystemState ())
let rec list_lookup :
  'a 'b . ('a * 'b) Prims.list -> 'a -> 'b FStar_Pervasives_Native.option =
  fun l x ->
    match l with
    | [] -> FStar_Pervasives_Native.None
    | (k, v)::tl ->
        if k = x then FStar_Pervasives_Native.Some v else list_lookup tl x
let rec list_bind :
  'a 'b . ('a * 'b) Prims.list -> 'a -> 'b -> ('a * 'b) Prims.list =
  fun l x v ->
    match l with
    | [] -> [(x, v)]
    | (k, v0)::tl ->
        if k = x then (x, v) :: tl else (k, v0) :: (list_bind tl x v)
let rec list_unbind :
  'a 'b . ('a * 'b) Prims.list -> 'a -> ('a * 'b) Prims.list =
  fun l x ->
    match l with
    | [] -> []
    | (k, v0)::tl -> if k = x then tl else (k, v0) :: (list_unbind tl x)
let rec list_contains : 'a . 'a Prims.list -> 'a -> Prims.bool =
  fun l x ->
    match l with
    | [] -> false
    | h::tl -> if h = x then true else list_contains tl x
let rec list_drop_val : 'a . 'a Prims.list -> 'a -> 'a Prims.list =
  fun l x ->
    match l with
    | [] -> []
    | h::tl ->
        if h = x then list_drop_val tl x else h :: (list_drop_val tl x)
let rec list_has_key : 'a 'b . ('a * 'b) Prims.list -> 'a -> Prims.bool =
  fun l x ->
    match l with
    | [] -> false
    | (k, uu___)::tl -> if k = x then true else list_has_key tl x
let rec iterAll : 'a . ('a -> unit) -> 'a Prims.list -> unit =
  fun f l -> match l with | [] -> () | h::tl -> (f h; iterAll f tl)
let pathToString (file_path1 : file_path) : Prims.string=
  Prims.strcat "/" (FStar_String.concat "/" file_path1)
let getFileId' (s : system_state) (file_path1 : file_path) :
  file_id FStar_Pervasives_Native.option=
  FStar_List_Tot_Base.fold_left
    (fun acc entry ->
       match acc with
       | FStar_Pervasives_Native.Some uu___ -> acc
       | FStar_Pervasives_Native.None ->
           let uu___ = entry in
           (match uu___ with
            | (fid, pentry) ->
                let uu___1 = pentry in
                (match uu___1 with
                 | (p, uu___2) ->
                     if p = file_path1
                     then FStar_Pervasives_Native.Some fid
                     else FStar_Pervasives_Native.None)))
    FStar_Pervasives_Native.None s.file_paths
let addUser (user_id1 : user_id) : unit=
  let uu___ =
    let uu___1 = let uu___2 = FStar_ST.op_Bang system in uu___2.users in
    list_contains uu___1 user_id1 in
  if uu___
  then ()
  else
    (let uu___2 =
       let uu___3 = FStar_ST.op_Bang system in
       let uu___4 =
         let uu___5 = let uu___6 = FStar_ST.op_Bang system in uu___6.users in
         FStar_List_Tot_Base.op_At uu___5 [user_id1] in
       {
         users = uu___4;
         next_file_id = (uu___3.next_file_id);
         next_handle = (uu___3.next_handle);
         file_paths = (uu___3.file_paths);
         file_contents = (uu___3.file_contents);
         file_permissions = (uu___3.file_permissions);
         file_handles = (uu___3.file_handles)
       } in
     FStar_ST.op_Colon_Equals system uu___2)
let removeUser (uid : user_id) : unit=
  let uu___ =
    let uu___1 = FStar_ST.op_Bang system in
    let uu___2 =
      let uu___3 = let uu___4 = FStar_ST.op_Bang system in uu___4.users in
      list_drop_val uu___3 uid in
    {
      users = uu___2;
      next_file_id = (uu___1.next_file_id);
      next_handle = (uu___1.next_handle);
      file_paths = (uu___1.file_paths);
      file_contents = (uu___1.file_contents);
      file_permissions = (uu___1.file_permissions);
      file_handles = (uu___1.file_handles)
    } in
  FStar_ST.op_Colon_Equals system uu___
let setUsers (users : user_id Prims.list) : unit=
  let uu___ =
    let uu___1 = FStar_ST.op_Bang system in
    {
      users;
      next_file_id = (uu___1.next_file_id);
      next_handle = (uu___1.next_handle);
      file_paths = (uu___1.file_paths);
      file_contents = (uu___1.file_contents);
      file_permissions = (uu___1.file_permissions);
      file_handles = (uu___1.file_handles)
    } in
  FStar_ST.op_Colon_Equals system uu___
let getUsers (uu___ : unit) : user_id Prims.list=
  let uu___1 = FStar_ST.op_Bang system in uu___1.users
let setAttr (file_path1 : file_path) (user_id1 : user_id)
  (permission1 : permission) : unit=
  let uu___ =
    let uu___1 = FStar_ST.op_Bang system in getFileId' uu___1 file_path1 in
  match uu___ with
  | FStar_Pervasives_Native.Some file_id1 ->
      let grants =
        let uu___1 =
          let uu___2 =
            let uu___3 = FStar_ST.op_Bang system in uu___3.file_permissions in
          list_lookup uu___2 file_id1 in
        match uu___1 with
        | FStar_Pervasives_Native.Some g -> g
        | FStar_Pervasives_Native.None -> [] in
      let current =
        match list_lookup grants user_id1 with
        | FStar_Pervasives_Native.Some ps -> ps
        | FStar_Pervasives_Native.None -> [] in
      let current1 =
        if list_contains current permission1
        then current
        else FStar_List_Tot_Base.op_At current [permission1] in
      let uu___1 =
        let uu___2 = FStar_ST.op_Bang system in
        let uu___3 =
          let uu___4 =
            let uu___5 = FStar_ST.op_Bang system in uu___5.file_permissions in
          list_bind uu___4 file_id1 (list_bind grants user_id1 current1) in
        {
          users = (uu___2.users);
          next_file_id = (uu___2.next_file_id);
          next_handle = (uu___2.next_handle);
          file_paths = (uu___2.file_paths);
          file_contents = (uu___2.file_contents);
          file_permissions = uu___3;
          file_handles = (uu___2.file_handles)
        } in
      FStar_ST.op_Colon_Equals system uu___1
  | FStar_Pervasives_Native.None -> ()
let fileExists (s : system_state) (f : file_path) : Prims.bool=
  match getFileId' s f with
  | FStar_Pervasives_Native.Some file_id1 ->
      ((list_has_key s.file_paths file_id1) &&
         (list_has_key s.file_contents file_id1))
        && (list_has_key s.file_permissions file_id1)
  | FStar_Pervasives_Native.None -> false
type ('f, 'h) fileExists_t = unit
let userHasPermission (s : system_state) (uid : user_id)
  (file_path1 : file_path) (permission1 : permission) : Prims.bool=
  match getFileId' s file_path1 with
  | FStar_Pervasives_Native.Some file_id1 ->
      (match list_lookup s.file_permissions file_id1 with
       | FStar_Pervasives_Native.Some grants ->
           (match list_lookup grants uid with
            | FStar_Pervasives_Native.Some ps -> list_contains ps permission1
            | FStar_Pervasives_Native.None -> false)
       | FStar_Pervasives_Native.None -> false)
  | FStar_Pervasives_Native.None -> false
type ('uid, 'fp, 'p, 'h) userHasPermission_t = unit
let createFile' (file_path1 : file_path) (is_dir1 : is_dir) : unit=
  let file_id1 = let uu___ = FStar_ST.op_Bang system in uu___.next_file_id in
  let s = FStar_ST.op_Bang system in
  FStar_ST.op_Colon_Equals system
    {
      users = (s.users);
      next_file_id = (s.next_file_id + Prims.int_one);
      next_handle = (s.next_handle);
      file_paths = (list_bind s.file_paths file_id1 (file_path1, is_dir1));
      file_contents = (list_bind s.file_contents file_id1 "");
      file_permissions = (list_bind s.file_permissions file_id1 []);
      file_handles = (s.file_handles)
    }
let createFile (file_path1 : file_path) (user_id1 : user_id)
  (is_dir1 : is_dir) : unit=
  (let uu___1 =
     let uu___2 = FStar_ST.op_Bang system in fileExists uu___2 file_path1 in
   if uu___1
   then failwith "file already exists"
   else createFile' file_path1 is_dir1);
  (let principals =
     if user_id1 = Prims.int_zero
     then [Prims.int_zero]
     else [Prims.int_zero; user_id1] in
   iterAll
     (fun uid ->
        iterAll (fun permission1 -> setAttr file_path1 uid permission1)
          [Open; Read; Write; AttrModify]) principals)
let openInternal (fh : file_handle) (uid : user_id) (file_path1 : file_path)
  : unit=
  let uu___ =
    let uu___1 = FStar_ST.op_Bang system in getFileId' uu___1 file_path1 in
  match uu___ with
  | FStar_Pervasives_Native.Some file_id1 ->
      let uu___1 =
        let uu___2 = FStar_ST.op_Bang system in
        let uu___3 =
          let uu___4 =
            let uu___5 = FStar_ST.op_Bang system in uu___5.next_handle in
          uu___4 + Prims.int_one in
        let uu___4 =
          let uu___5 =
            let uu___6 = FStar_ST.op_Bang system in uu___6.file_handles in
          list_bind uu___5 fh (file_id1, uid) in
        {
          users = (uu___2.users);
          next_file_id = (uu___2.next_file_id);
          next_handle = uu___3;
          file_paths = (uu___2.file_paths);
          file_contents = (uu___2.file_contents);
          file_permissions = (uu___2.file_permissions);
          file_handles = uu___4
        } in
      FStar_ST.op_Colon_Equals system uu___1
  | FStar_Pervasives_Native.None -> ()
let startServer (users : user_id Prims.list) : unit=
  FStar_ST.op_Colon_Equals system (getFreshSystemState ());
  createFile [] Prims.int_zero true;
  addUser Prims.int_zero;
  iterAll (fun user_id1 -> addUser user_id1) users;
  iterAll (fun user_id1 -> setAttr [] user_id1 Open) users
let nfsMount (user_id1 : user_id) : file_handle=
  let fh = let uu___ = FStar_ST.op_Bang system in uu___.next_handle in
  let root_file_path = [] in
  let uu___ =
    let uu___1 = FStar_ST.op_Bang system in
    userHasPermission uu___1 user_id1 root_file_path Open in
  if uu___
  then (openInternal fh user_id1 root_file_path; fh)
  else failwith "user does not have permission to mount"
let nfsOpen (parent_fh : file_handle) (file_name1 : file_name) (id1 : id)
  (create_file : Prims.bool) : file_handle=
  let parent_file_id =
    let uu___ =
      let uu___1 =
        let uu___2 = FStar_ST.op_Bang system in uu___2.file_handles in
      list_lookup uu___1 parent_fh in
    match uu___ with
    | FStar_Pervasives_Native.Some (file_id1, file_user_id) ->
        if id1 = file_user_id
        then file_id1
        else failwith "OPEN: parent file handle does not belong to user"
    | FStar_Pervasives_Native.None ->
        failwith "OPEN: parent file handle not found" in
  let parent_file_path =
    let uu___ =
      let uu___1 = let uu___2 = FStar_ST.op_Bang system in uu___2.file_paths in
      list_lookup uu___1 parent_file_id in
    match uu___ with
    | FStar_Pervasives_Native.Some (file_path1, is_dir1) ->
        if is_dir1
        then file_path1
        else failwith "OPEN: parent file handle does not refer to directory"
    | FStar_Pervasives_Native.None ->
        failwith "OPEN: parent file handle does not map to a valid path" in
  let file_path1 = FStar_List_Tot_Base.op_At parent_file_path [file_name1] in
  if create_file then createFile file_path1 id1 false else ();
  (let fh = let uu___1 = FStar_ST.op_Bang system in uu___1.next_handle in
   let uu___1 =
     let uu___2 = FStar_ST.op_Bang system in
     userHasPermission uu___2 id1 file_path1 Open in
   if uu___1
   then (openInternal fh id1 file_path1; fh)
   else failwith "OPEN: user does not have permission to open file")
