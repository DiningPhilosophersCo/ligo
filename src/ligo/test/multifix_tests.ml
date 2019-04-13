open Trace
open Test_helpers
open Ligo.Parser_multifix

let basic () : unit result =
  let%bind _ = User.parse_file "./contracts/new-syntax.mligo" in
  ok ()

let simplify () : unit result =
  let%bind raw = User.parse_file "./contracts/basic.mligo" in
  let%bind _simpl = Ligo.Simplify_multifix.main raw in
  ok ()

let integration () : unit result =
  let%bind raw = User.parse_file "./contracts/basic.mligo" in
  let%bind simpl = Ligo.Simplify_multifix.main raw in
  let%bind typed = Ligo.Typer.type_program (Location.unwrap simpl) in
  let%bind result = Ligo.easy_evaluate_typed "foo" typed in
  Ligo.AST_Typed.assert_value_eq (Ligo.AST_Typed.Combinators.e_a_int (42 + 127), result)

let main = "Multifix", [
    test "basic" basic ;
    test "simplfiy" simplify ;
    test "integration" integration ;
]
