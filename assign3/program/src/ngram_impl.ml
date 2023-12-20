exception Unimplemented

type ngram = string list
type ngram_map = (ngram, string list) Core.Map.Poly.t
type word_distribution = float Core.String.Map.t

let rec remove_last_impl1 (l : string list) : string list =
  match l with [] -> [] | _ :: [] -> [] | h :: t -> h :: remove_last_impl1 t
;;

assert (remove_last_impl1 [ "a"; "b" ] = [ "a" ])

let remove_last_impl2 (l : string list) : string list =
  let len = List.length l in
  List.filteri (fun i _ -> i <> len - 1) l
;;

assert (remove_last_impl2 [ "a"; "b" ] = [ "a" ])

let rec n_elements (len : int) (lst : string list) : string list =
  if List.length lst >= len then
    match (lst, len) with
    | _, 0 -> []
    | h :: t, m -> h :: n_elements (m - 1) t
    | [], _ -> failwith "n_elements"
  else []

let rec compute_ngrams (l : string list) (n : int) : string list list =
  match l with
  | [] -> []
  | l when List.length l < n -> []
  | _ :: t -> n_elements n l :: compute_ngrams t n
;;

assert (
  compute_ngrams [ "a"; "b"; "c"; "d" ] 3
  = [ [ "a"; "b"; "c" ]; [ "b"; "c"; "d" ] ])

let ngram_to_string ng = Printf.sprintf "[%s]" (Core.String.concat ~sep:", " ng)
let ngram_map_new () : ngram_map = Core.Map.Poly.empty

let ngram_map_add (map : ngram_map) (ngram : ngram) : ngram_map =
  let ng, label = Core.List.(split_n ngram (length ngram - 1)) in
  let find, set = Core.Map.Poly.(find, set) in
  match find map ng with
  | None -> set map ~key:ng ~data:label
  | Some value -> set map ~key:ng ~data:(label @ value)

let ngram_map_distribution (map : ngram_map) (ngram : ngram) :
    word_distribution option =
  match Core.Map.Poly.find map ngram with
  | None -> None
  | Some lst ->
      let len = lst |> List.length |> float_of_int in
      Some
        (lst
        |> List.map (fun a -> (a, 1. /. len))
        |> Core.String.Map.of_alist_reduce ~f:( +. ))

let distribution_to_string (dist : word_distribution) : string =
  Core.(Sexp.to_string_hum (String.Map.sexp_of_t Float.sexp_of_t dist))

let sample_distribution (dist : word_distribution) : string =
  Core.Map.fold dist
    ~init:(Random.float 1., " ")
    ~f:(fun ~key ~data (num, str) ->
      if num < 0. then (num, str) else (num -. data, key))
  |> snd

let rec sample_n (map : ngram_map) (ng : ngram) (n : int) : string list =
  match n with
  | 0 -> []
  | k -> (
      match ngram_map_distribution map ng with
      | None -> []
      | Some dist ->
          let next = sample_distribution dist in
          next :: sample_n map List.((ng |> tl) @ [ next ]) (k - 1))

let a =
  let map = ngram_map_new () in
  let map = ngram_map_add map [ "a"; "b"; "c" ] in
  let map = ngram_map_add map [ "b"; "c"; "d" ] in
  let map = ngram_map_add map [ "c"; "d"; "c" ] in
  let map = ngram_map_add map [ "d"; "c"; "a" ] in
  let map = ngram_map_add map [ "c"; "a"; "b" ] in
  sample_n map [ "a"; "b" ] 50
