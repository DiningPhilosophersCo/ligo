open Js_of_ocaml

let source = {|

type storage = int
type parameter =
  Increment of int
| Decrement of int
| Reset
type return = operation list * storage
// Two entrypoints
let add (store, delta : storage * int) : storage = store + delta
let sub (store, delta : storage * int) : storage = store - delta
(* Main access point that dispatches to the entrypoints according to
   the smart contract parameter. *)
let main (action, store : parameter * storage) : return =
 ([] : operation list),    // No operations
 (match action with
   Increment (n) -> add (store, n)
 | Decrement (n) -> sub (store, n)
 | Reset         -> 0)

|}


let main source =
  let werror = false in
  let entry_point = "main" in
  let oc_views = [] in
  let syntax = "camelgo" in
  let protocol_version = "hangzhou" in
  let display_format = Simple_utils.Display.human_readable in
  let disable_typecheck = false in
  let michelson_format = `Text in
  let michelson_comments = [`Source] in
  let project_root = None in
  match Ligo_api_compile.Compile.contract_string ~werror source entry_point oc_views syntax protocol_version display_format disable_typecheck michelson_format michelson_comments project_root () with
  | Ok (a, b) -> print_endline a; print_endline b; a | Error (a, b) -> print_endline "error"; print_endline a; print_endline b; "<failed>"


(* let () = print_endline "hey" *)
let _ =
  Js.export "compile"
    (object%js
      method main str = Js.to_string str |> main |> Js.string
     end)

(* let () = main source *)
