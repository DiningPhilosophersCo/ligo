let () =
  let werror = false in
  let source_file = "/some/file.mligo" in
  let entry_point = "main" in
  let oc_views = [] in
  let syntax = "cameligo" in
  let protocol_version = "10.0" in
  let display_format = Simple_utils.Display.human_readable in
  let disable_typecheck = false in
  let michelson_format = `Text in
  let michelson_comments = [`All] in
  let project_root = None in
  match Ligo_api.Compile.contract_string ~werror source_file entry_point oc_views syntax protocol_version display_format disable_typecheck michelson_format michelson_comments project_root () with
  | Ok _ -> print_endline "ok"
  | Error _ -> print_endline "error"

