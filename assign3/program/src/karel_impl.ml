open Base.Option.Monad_infix

exception Unimplemented

(* Set this to true to print out intermediate state between Karel steps *)
let debug = false

type cell = Empty | Wall | Beeper
type grid = cell list list
type dir = North | West | South | East
type pos = int * int
type state = { karel_pos : pos; karel_dir : dir; grid : grid }

let get_cell (grid : grid) ((i, j) : pos) : cell option =
  Core.List.nth grid j >>= fun l -> Core.List.nth l i

let set_cell (grid : grid) ((i, j) : pos) (cell : cell) : grid =
  Core.List.mapi grid ~f:(fun j' l ->
      if j = j' then
        Core.List.mapi l ~f:(fun i' c -> if i = i' then cell else c)
      else l)

let init_string_grid m n =
  Core.List.init m ~f:(fun _ -> Core.List.init n ~f:(fun _ -> '.'))

let set_string_grid grid string_grid =
  Core.List.mapi string_grid ~f:(fun i row ->
      Core.List.mapi row ~f:(fun j elm ->
          match get_cell grid (j, i) with
          | Some Wall -> 'X'
          | Some Beeper -> 'B'
          | _ -> elm))

let set_karel pos string_grid =
  Core.List.mapi string_grid ~f:(fun i row ->
      Core.List.mapi row ~f:(fun j elm -> if pos = (j, i) then 'K' else elm))

let state_to_string (state : state) : string =
  match state with
  | { karel_pos; grid; _ } ->
      init_string_grid (List.length grid) (grid |> List.hd |> List.length)
      |> set_string_grid grid |> set_karel karel_pos
      |> Core.List.map ~f:(Core.List.map ~f:(String.make 1))
      |> Core.List.map ~f:(String.concat " ")
      |> String.concat "\n"

let empty_grid (m : int) (n : int) : grid =
  Core.List.map (Core.List.range 0 m) ~f:(fun _ ->
      Core.List.map (Core.List.range 0 n) ~f:(fun _ -> Empty))

type predicate =
  | FrontIs of cell
  | NoBeepersPresent
  | Facing of dir
  | Not of predicate

type instruction =
  | Move
  | TurnLeft
  | PickBeeper
  | PutBeeper
  | While of predicate * instruction list
  | If of predicate * instruction list * instruction list

let rec predicate_to_string (pred : predicate) : string =
  match pred with
  | FrontIs c ->
      let cellstr =
        match c with Empty -> "Empty" | Beeper -> "Beeper" | Wall -> "Wall"
      in
      Printf.sprintf "FrontIs(%s)" cellstr
  | NoBeepersPresent -> "NoBeepersPresent"
  | Facing dir ->
      let dirstr =
        match dir with
        | North -> "North"
        | South -> "South"
        | East -> "East"
        | West -> "West"
      in
      Printf.sprintf "Facing(%s)" dirstr
  | Not pred' -> Printf.sprintf "Not(%s)" (predicate_to_string pred')

let rec instruction_to_string (instr : instruction) : string =
  match instr with
  | Move -> "Move"
  | TurnLeft -> "TurnLeft"
  | PickBeeper -> "PickBeeper"
  | PutBeeper -> "PutBeeper"
  | While (pred, instrs) ->
      Printf.sprintf "While(%s, [%s])" (predicate_to_string pred)
        (instruction_list_to_string instrs)
  | If (pred, then_, else_) ->
      Printf.sprintf "If(%s, [%s], [%s])" (predicate_to_string pred)
        (instruction_list_to_string then_)
        (instruction_list_to_string else_)

and instruction_list_to_string (instrs : instruction list) : string =
  Core.String.concat ~sep:", " (Core.List.map ~f:instruction_to_string instrs)

let get_next_pos = function
  | { karel_pos = cur_x, cur_y; karel_dir; _ } ->
      let next_x, next_y =
        match karel_dir with
        | North -> (cur_x, cur_y - 1)
        | South -> (cur_x, cur_y + 1)
        | East -> (cur_x + 1, cur_y)
        | West -> (cur_x - 1, cur_y)
      in
      (next_x, next_y)

let rec eval_pred (state : state) (pred : predicate) : bool =
  let next_x, next_y = get_next_pos state in
  match (state, pred) with
  | { grid; _ }, FrontIs c -> (
      match get_cell grid (next_x, next_y) with
      | None -> false
      | Some cc -> cc = c)
  | { karel_pos = cur_x, cur_y; grid; _ }, NoBeepersPresent -> (
      match get_cell grid (cur_x, cur_y) with Some Beeper -> true | _ -> false)
  | { karel_dir; _ }, Facing d -> d = karel_dir
  | _, Not p -> eval_pred state p

let rec step (state : state) (code : instruction) : state =
  match (state, code) with
  | { grid; _ }, Move -> (
      let next_pos = get_next_pos state in
      match get_cell grid next_pos with
      | Some Empty | Some Beeper -> { state with karel_pos = next_pos }
      | _ -> state)
  | { karel_dir; _ }, TurnLeft -> (
      match karel_dir with
      | North -> { state with karel_dir = West }
      | South -> { state with karel_dir = East }
      | East -> { state with karel_dir = North }
      | West -> { state with karel_dir = South })
  | { karel_pos; grid; _ }, PickBeeper ->
      { state with grid = set_cell grid karel_pos Empty }
  | { karel_pos; grid; _ }, PutBeeper ->
      { state with grid = set_cell grid karel_pos Beeper }
  | s, While (pred, instrs) ->
      if eval_pred state pred then
        step (step_list state instrs) (While (pred, instrs))
      else s
  | s, If (pred, then_, else_) ->
      if eval_pred s pred then step_list s then_ else step_list s else_

and step_list (state : state) (instrs : instruction list) : state =
  Core.List.fold instrs ~init:state ~f:(fun state instr ->
      if debug then (
        Printf.printf "Executing instruction %s...\n"
          (instruction_to_string instr);
        let state' = step state instr in
        Printf.printf "Executed instruction %s. New state:\n%s\n"
          (instruction_to_string instr)
          (state_to_string state');
        state')
      else step state instr)

let checkers_algo : instruction list =
  [
    While
      ( FrontIs Empty,
        [
          PutBeeper;
          While
            ( FrontIs Empty,
              [ Move; If (FrontIs Empty, [ Move; PutBeeper ], []) ] );
          If
            ( Facing East,
              [
                TurnLeft;
                TurnLeft;
                TurnLeft;
                If
                  ( FrontIs Empty,
                    [
                      If
                        ( NoBeepersPresent,
                          [ Move; PutBeeper; TurnLeft; TurnLeft; TurnLeft ],
                          [ Move; TurnLeft; TurnLeft; TurnLeft ] );
                    ],
                    [] );
              ],
              [
                TurnLeft;
                If
                  ( FrontIs Empty,
                    [
                      If
                        ( NoBeepersPresent,
                          [ Move; PutBeeper; TurnLeft ],
                          [ Move; TurnLeft ] );
                    ],
                    [] );
              ] );
        ] );
  ]
