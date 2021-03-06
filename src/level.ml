open Graphics
open Raylib
open Yojson.Basic.Util

let _ = Random.self_init ()
let tile_width = 96
let tile_height = 96

type tile =
  | Grass
  | Water
  | Road
  | Exit

type t = {
  grid : tile array array;
  (* grid : string list list; *)
  level_id : string;
  width : int;
  height : int;
  start_x : int;
  start_y : int;
}

let from_json_tiles json =
  json |> member "tiles" |> to_list |> List.map to_list
  |> List.map (List.map to_string)

let rec match_tiles list acc =
  match list with
  | [] -> acc
  | h :: t ->
      if h = "grass" then acc @ [ Grass ] @ match_tiles t acc
      else if h = "water" then acc @ [ Water ] @ match_tiles t acc
      else if h = "road" then acc @ [ Road ] @ match_tiles t acc
      else if h = "exit" then acc @ [ Exit ] @ match_tiles t acc
      else failwith "invalid tile type"

let rec getlist list =
  let newlist = [] in
  match list with
  | [] -> newlist
  | h :: t -> (match_tiles h [] :: getlist t) @ newlist

let from_json json =
  {
    grid =
      json |> from_json_tiles |> getlist |> List.map Array.of_list
      |> Array.of_list;
    level_id = json |> member "id" |> to_string;
    width = json |> member "width" |> to_int;
    height = json |> member "height" |> to_int;
    start_x =
      json |> member "start_tile_x" |> to_int |> ( * ) tile_height;
    start_y =
      json |> member "start_tile_y" |> to_int |> ( * ) tile_height;
  }

let start_location lvl = (lvl.start_x + 48, lvl.start_y + 48)
let get_map lvl = lvl.level_id

let create_grid width height =
  Array.init width (fun _ ->
      Array.init height (fun _ ->
          if Random.bool () then Road
          else if Random.bool () then Water
          else Grass))

let init_lvl width height =
  {
    grid = create_grid width height;
    level_id = "test";
    width;
    height;
    start_x = 0;
    start_y = 0;
  }

let get_tile x y lvl = Array.get (Array.get lvl.grid y) x
let set_tile x y lvl tile = Array.set (Array.get lvl.grid y) x tile

(* taken from somewhere *)
let load path =
  let tex = Raylib.load_texture path in
  Gc.finalise Raylib.unload_texture tex;
  tex

let gtilewidth = 96.
let gtileheight = 48.

let draw_lvl lvl =
  let ground = load "assets/ground.png" in
  (* let water = load "assets/ground.png" in let road = load
     "assets/ground.png" in *)
  for i = 0 to lvl.width - 1 do
    for j = 0 to lvl.height - 1 do
      match get_tile i j lvl with
      | Grass ->
          Raylib.draw_texture_rec ground
            (Rectangle.create 0. gtileheight gtilewidth gtilewidth)
            (Vector2.create
               (float_of_int (i * tile_width))
               (float_of_int (j * tile_width)))
            Color.white
      | Water ->
          Raylib.draw_texture_rec ground
            (Rectangle.create (gtilewidth *. 3.) (gtileheight *. 7.)
               gtilewidth gtilewidth)
            (Vector2.create
               (float_of_int (i * tile_width))
               (float_of_int (j * tile_width)))
            Color.white
      | Road ->
          Raylib.draw_texture_rec ground
            (Rectangle.create (gtilewidth *. 1.) (gtileheight *. 1.)
               gtilewidth gtilewidth)
            (Vector2.create
               (float_of_int (i * tile_width))
               (float_of_int (j * tile_width)))
            Color.white
      | Exit ->
          Raylib.draw_texture_rec ground
            (Rectangle.create (gtilewidth *. 2.) (gtileheight *. 1.)
               gtilewidth gtilewidth)
            (Vector2.create
               (float_of_int (i * tile_width))
               (float_of_int (j * tile_width)))
            Color.white
    done
  done
(* Graphics.set_color (rgb 128 170 255); Graphics.fill_rect 0 0 600 90;
   Graphics.set_color (rgb 179 242 255); Graphics.fill_rect 10 5 280 80;
   Graphics.set_color (rgb 179 242 255); Graphics.fill_rect 310 5 280
   80; Graphics.set_color (rgb 0 0 0); Graphics.moveto 400 65;
   Graphics.draw_string "Press WASD to move"; Graphics.moveto 400 40;
   Graphics.draw_string "Press f to fight"; Graphics.moveto 400 15;
   Graphics.draw_string "Press q to quit" *)

let level_array =
  Sys.readdir ("data" ^ Filename.dir_sep ^ "level" ^ Filename.dir_sep)

let random_level =
  level_array |> Array.length |> Random.int |> Array.get level_array
  |> ( ^ ) ("data" ^ Filename.dir_sep ^ "level" ^ Filename.dir_sep)
  |> Yojson.Basic.from_file |> from_json

let rec search lst index x =
  match lst with
  | [] -> raise (Failure "Not Found")
  | hd :: tl ->
      if hd = x ^ ".json" then index else search tl (index + 1) x

let next_level lvl =
  lvl |> get_map
  |> search (level_array |> Array.to_list) 0
  |> (fun i -> if i + 1 = Array.length level_array then 0 else i + 1)
  |> Array.get level_array
  |> ( ^ ) ("data" ^ Filename.dir_sep ^ "level" ^ Filename.dir_sep)
  |> Yojson.Basic.from_file |> from_json