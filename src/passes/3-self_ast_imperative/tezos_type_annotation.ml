open Ast_imperative
open Trace

module Errors = struct
  let bad_string_timestamp ts loc () =
    let title = (thunk ("Badly formatted timestamp \""^ts^"\"")) in
    let message () = "" in
    let data = [
      ("location" , fun () -> Format.asprintf "%a" Location.pp loc)
    ] in
    error ~data title message ()
end
open Errors

let peephole_expression : expression -> expression result = fun e ->
  let return expression_content = ok { e with expression_content } in
  match e.expression_content with
  | E_ascription {anno_expr=e'; type_annotation=t} as e -> (
      match (e'.expression_content , t.type_content) with
      | (E_literal (Literal_string s) , T_constant (TC_key_hash))  -> return @@ E_literal (Literal_key_hash (Ligo_string.extract s))
      | (E_literal (Literal_string s) , T_constant (TC_signature)) -> return @@ E_literal (Literal_signature (Ligo_string.extract s))
      | (E_literal (Literal_string s) , T_constant (TC_key))       -> return @@ E_literal (Literal_key (Ligo_string.extract s))
      | (E_literal (Literal_int i) , T_constant (TC_timestamp))    -> return @@ E_literal (Literal_timestamp i)
      | (E_literal (Literal_string str) , T_constant (TC_timestamp)) ->
        let str = Ligo_string.extract str in
        let%bind time =
          trace_option (bad_string_timestamp str e'.location)
          @@ Memory_proto_alpha.Protocol.Alpha_context.Timestamp.of_notation str in
        let itime = Z.of_int64 @@ Tezos_utils.Time.Protocol.to_seconds time in
        return @@ E_literal (Literal_timestamp itime)
      | (E_literal (Literal_string str) , T_constant (TC_address)) -> return @@ E_literal (Literal_address (Ligo_string.extract str))
      | (E_literal (Literal_string str) , T_constant (TC_bytes)) -> (
        let str = Ligo_string.extract str in
        let%bind e' = e'_bytes str in
        return e'
      )
      | _ -> return e
    )
  | e -> return e
