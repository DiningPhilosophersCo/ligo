open Trace
open Ast_core
open Test_helpers
open Main_errors

module Typed = Ast_typed
module Typer = Typer
module Simplified = Ast_core

let int () : (unit, _) result =
  let open Combinators in
  let pre = e_int (Z.of_int 32) in
  let open Typer in
  let e = Environment.empty in
  let state = Typer.Solver.initial_state in
  let%bind (post , new_state) = trace typer_tracer @@ type_expression_subst typer_switch e state pre in
  let () = Typer.Solver.discard_state new_state in
  let open! Typed in
  let open Combinators in
  let%bind () = trace_option (test_internal __LOC__) @@ assert_type_expression_eq (post.type_expression, t_int ()) in
  ok ()

let init_env = Environment.default Environment.Protocols.current

module TestExpressions = struct
  let test_expression ?(env = init_env)
                      ?(state = Typer.Solver.initial_state)
                      (expr : expression)
                      (test_expected_ty : Typed.type_expression) =
    let pre = expr in
    let open Typer in
    let open! Typed in
    let%bind (post , new_state) = trace typer_tracer @@ type_expression_subst typer_switch env state pre in
    let () = Typer.Solver.discard_state new_state in
    let%bind () = trace_option (test_internal __LOC__) @@ assert_type_expression_eq (post.type_expression, test_expected_ty) in
    ok ()

  module I = Simplified.Combinators
  module O = Typed.Combinators
  module E = Typed.Environment

  let unit   () : (unit, _) result = test_expression I.(e_unit ())    O.(t_unit ())
  let int    () : (unit, _) result = test_expression I.(e_int (Z.of_int 32))     O.(t_int ())
  let bool   () : (unit, _) result = test_expression I.(e_bool true)  O.(t_bool ())
  let string () : (unit, _) result = test_expression I.(e_string (Standard "s")) O.(t_string ())
  let bytes  () : (unit, _) result =
    let b = I.e_bytes_hex "0b" in
    test_expression b  O.(t_bytes ())

  let lambda () : (unit, _) result =
    test_expression
      I.(e_lambda_ez (Location.wrap @@ Var.of_name "x") ~ascr:(t_int ()) (Some (t_int ())) (e_var "x"))
      O.(t_function (t_int ()) (t_int ()) ())

  let tuple () : (unit, _) result =
    test_expression
      I.(e_record @@ LMap.of_list [(Label "0",e_int (Z.of_int 32)); (Label "1", e_string (Standard "foo"))])
      O.(make_t_ez_record [("0",t_int ()); ("1",t_string ())])

  let constructor () : (unit, _) result =
    let variant_foo_bar = Ast_typed.t_sum_ez [
        ("foo", Typed.t_int () );
        ("bar", Typed.t_string () ); ]
    in
    test_expression
      ~env:(E.add_type (Var.of_name "test_t") variant_foo_bar E.empty)
      I.(e_constructor "foo" (e_int (Z.of_int 32)))
      variant_foo_bar

  let record () : (unit, _) result =
    test_expression
      I.(e_record @@ LMap.of_list [(Label "foo", e_int (Z.of_int 32)); (Label "bar", e_string (Standard "foo"))])
      O.(make_t_ez_record [("foo", t_int ()); ("bar", t_string ())])


end
(* TODO: deep types (e.g. record of record)
   TODO: negative tests (expected type error) *)

let main = test_suite "Typer (from core AST)" [
    test "int" int ;
    test "unit"        TestExpressions.unit ;
    test "int2"        TestExpressions.int ;
    test "bool"        TestExpressions.bool ;
    test "string"      TestExpressions.string ;
    test "bytes"       TestExpressions.bytes ;
    test "tuple"       TestExpressions.tuple ;
    test "constructor" TestExpressions.constructor ;
    test "record"      TestExpressions.record ;
    test "lambda"      TestExpressions.lambda ;
  ]
