exception Unimplemented

type ngram = string list
type ngram_map = (ngram, string list) Core.Map.Poly.t
type word_distribution = float Core.String.Map.t

let rec remove_last_impl1 (l : string list) : string list =
  raise Unimplemented
;;

assert (remove_last_impl1 [ "a"; "b" ] = [ "a" ])

let remove_last_impl2 (l : string list) : string list =
  raise Unimplemented
;;

assert (remove_last_impl2 [ "a"; "b" ] = [ "a" ])

let rec compute_ngrams (l : string list) (n : int) : string list list =
  raise Unimplemented
;;

assert (
  compute_ngrams [ "a"; "b"; "c"; "d" ] 3
  = [ [ "a"; "b"; "c" ]; [ "b"; "c"; "d" ] ])

let ngram_to_string ng = Printf.sprintf "[%s]" (Core.String.concat ~sep:", " ng)
let ngram_map_new () : ngram_map = Core.Map.Poly.empty

let ngram_map_add (map : ngram_map) (ngram : ngram) : ngram_map =
  raise Unimplemented


let ngram_map_distribution (map : ngram_map) (ngram : ngram) :
    word_distribution option =
  raise Unimplemented

let distribution_to_string (dist : word_distribution) : string =
  Core.(Sexp.to_string_hum (String.Map.sexp_of_t Float.sexp_of_t dist))

let sample_distribution (dist : word_distribution) : string =
  raise Unimplemented

let rec sample_n (map : ngram_map) (ng : ngram) (n : int) : string list =
  raise Unimplemented

let a =
  let map = ngram_map_new () in
  let map = ngram_map_add map [ "a"; "b"; "c" ] in
  let map = ngram_map_add map [ "b"; "c"; "d" ] in
  let map = ngram_map_add map [ "c"; "d"; "c" ] in
  let map = ngram_map_add map [ "d"; "c"; "a" ] in
  let map = ngram_map_add map [ "c"; "a"; "b" ] in
  sample_n map [ "a"; "b" ] 50
