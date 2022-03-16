let () =
  let werror = false in
  let source_file = {|
type storage = int
type parameter = unit
type return = operation list * storage
let main (_, _store : parameter * storage) : return =
 ([] : operation list), 1000   // No operations


|} in
  let entry_point = "main" in
  let oc_views = [] in
  let syntax = "camelgo" in
  let protocol_version = "hangzhou" in
  let display_format = Simple_utils.Display.human_readable in
  let disable_typecheck = false in
  let michelson_format = `Text in
  let michelson_comments = [`All] in
  let project_root = None in
  match Ligo_api_compile.Compile.contract_string ~werror source_file entry_point oc_views syntax protocol_version display_format disable_typecheck michelson_format michelson_comments project_root () with
  | Ok _ -> print_endline "ok"
  | Error (a, b) -> print_endline "error"; print_endline a; print_endline b 


(* let () = print_endline "hey" *)
