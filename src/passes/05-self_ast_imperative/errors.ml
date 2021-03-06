module Snippet = Simple_utils.Snippet
module PP_helpers = Simple_utils.PP_helpers
open Simple_utils.Display
open Ast_imperative

let stage = "self_ast_imperative"

type self_ast_imperative_error = [
  | `Self_ast_imperative_long_constructor of (string * type_expression)
  | `Self_ast_imperative_bad_timestamp of (string * expression)
  | `Self_ast_imperative_bad_format_literal of expression
  | `Self_ast_imperative_bad_empty_arity of (constant' * expression)
  | `Self_ast_imperative_bad_single_arity of (constant' * expression)
  | `Self_ast_imperative_bad_map_param_type of (constant' * expression)
  | `Self_ast_imperative_bad_set_param_type of (constant' * expression)
  | `Self_ast_imperative_bad_conversion_bytes of expression
  | `Self_ast_imperative_vars_captured of (location * expression_variable) list
  | `Self_ast_imperative_const_assigned of (location * expression_variable)
  | `Self_ast_imperative_no_shadowing of location
  | `Self_ast_imperative_non_linear_pattern of type_expression pattern
  | `Self_ast_imperative_non_linear_record of expression
  | `Self_ast_imperative_non_linear_type_decl of type_expression
  | `Self_ast_imperative_non_linear_row of type_expression
  | `Self_ast_imperative_duplicate_parameter of expression
  | `Self_ast_imperative_reserved_name of (string * location)
] [@@deriving poly_constructor { prefix = "self_ast_imperative_" }]

let error_ppformat : display_format:string display_format ->
  Format.formatter -> self_ast_imperative_error -> unit =
  fun ~display_format f a ->
  match display_format with
  | Human_readable | Dev -> (
    match a with
    | `Self_ast_imperative_non_linear_record e ->
      Format.fprintf f
        "@[<v>%a@.Duplicated record field@.Hint: Change the name.@]"
        Snippet.pp e.location
    | `Self_ast_imperative_reserved_name (str,loc) ->
      Format.fprintf f
        "@[<v>%a@.Reserved name %S.@.Hint: Change the name.@]"
        Snippet.pp loc
        str
    | `Self_ast_imperative_non_linear_pattern t ->
      Format.fprintf f
        "@[<v>%a@.Repeated variable in pattern.@.Hint: Change the name.@]"
        Snippet.pp t.location
    | `Self_ast_imperative_non_linear_type_decl t ->
      Format.fprintf f
        "@[<v>%a@.Repeated type variable in type.@.Hint: Change the name.@]"
        Snippet.pp t.location
    | `Self_ast_imperative_non_linear_row t ->
      Format.fprintf f
        "@[<v>%a@.Duplicated field or variant name.@.Hint: Change the name.@]"
        Snippet.pp t.location
    | `Self_ast_imperative_duplicate_parameter exp ->
      Format.fprintf f
        "@[<v>%a@.Duplicated variable name in function parameter.@.Hint: Change the name.@]"
        Snippet.pp exp.location
    | `Self_ast_imperative_long_constructor (c,e) ->
      Format.fprintf f
        "@[<hv>%a@ Ill-formed data constructor \"%s\".@.Data constructors have a maximum length of 32 characters, which is a limitation imposed by annotations in Tezos. @]"
        Snippet.pp e.location
        c
    | `Self_ast_imperative_bad_timestamp (t,e) ->
      Format.fprintf f
        "@[<hv>%a@ Ill-formed timestamp \"%s\".@.At this point, a string with a RFC3339 notation or the number of seconds since Epoch is expected. @]"
        Snippet.pp e.location
        t
    | `Self_ast_imperative_bad_format_literal e ->
      Format.fprintf f
        "@[<hv>%a@ Ill-formed literal \"%a\".@.In the case of an address, a string is expected prefixed by either tz1, tz2, tz3 or KT1 and followed by a Base58 encoded hash and terminated by a 4-byte checksum.@.In the case of a key_hash, signature, or key a Base58 encoded hash is expected. @]"
        Snippet.pp e.location
        Ast_imperative.PP.expression e
    | `Self_ast_imperative_bad_empty_arity (c, e) ->
      Format.fprintf f
        "@[<hv>%a@ Ill-formed \"%a\" expression.@.No functions arguments are expected. @]"
        Snippet.pp e.location PP.constant' c
    | `Self_ast_imperative_bad_single_arity (c, e) ->
      Format.fprintf f
        "@[<hv>%a@ Ill-formed \"%a\" expression@.One function argument is expected. @]"
        Snippet.pp e.location PP.constant' c
    | `Self_ast_imperative_bad_map_param_type (c,e) ->
      Format.fprintf f
        "@[<hv>%a@ Ill-formed \"%a\" expression.@.A list of pair parameters is expected.@]"
        Snippet.pp e.location PP.constant' c
    | `Self_ast_imperative_bad_set_param_type (c,e) ->
      Format.fprintf f
        "@[<hv>%a@ Ill-formed \"%a\" expression.@.A list of pair parameters is expected.@]"
        Snippet.pp e.location PP.constant' c
    | `Self_ast_imperative_bad_conversion_bytes e ->
      Format.fprintf f
        "@[<hv>%a@ Ill-formed bytes literal.@.Example of a valid bytes literal: \"ff7a7aff\". @]"
        Snippet.pp e.location
    | `Self_ast_imperative_vars_captured vars ->
       let pp_var ppf ((decl_loc, var) : location * expression_variable) =
         Format.fprintf ppf
           "@[<hv>%a@ Invalid capture of non-constant variable \"%a\", declared at@.%a@]"
           Snippet.pp (ValueVar.get_location var) PP.expression_variable var Snippet.pp decl_loc in
       Format.fprintf f "%a" (PP_helpers.list_sep pp_var (PP_helpers.tag "@.")) vars
    | `Self_ast_imperative_const_assigned (loc, var) ->
       Format.fprintf f
         "@[<hv>%a@ Invalid assignment to constant variable \"%a\", declared at@.%a@]"
         Snippet.pp loc PP.expression_variable var Snippet.pp (ValueVar.get_location var)
    | `Self_ast_imperative_no_shadowing l ->
        Format.fprintf f
            "@[<hv>%a@ Cannot redeclare block-scoped variable. @]"
            Snippet.pp l
  )

let error_jsonformat : self_ast_imperative_error -> json = fun a ->
  let json_error ~stage ~content =
    `Assoc [
      ("status", `String "error") ;
      ("stage", `String stage) ;
      ("content",  content )]
  in
  match a with
  | `Self_ast_imperative_non_linear_record e ->
    let message = `String (Format.asprintf "Duplicated record field") in
    let loc = Location.to_yojson e.location in
    let content = `Assoc [
      ("message", message);
      ("location", loc);
    ] in
    json_error ~stage ~content
  | `Self_ast_imperative_reserved_name (str,loc) ->
    let message = `String (Format.asprintf "reserved name %s" str) in
    let loc = Location.to_yojson loc in
    let content = `Assoc [
      ("message", message);
      ("location", loc);
    ] in
    json_error ~stage ~content
  | `Self_ast_imperative_non_linear_pattern t ->
    let message = `String "Repeated variable in pattern" in
    let loc = Location.to_yojson t.location in
    let content = `Assoc [
      ("message", message);
      ("location", loc);
    ] in
    json_error ~stage ~content
  | `Self_ast_imperative_non_linear_type_decl t ->
    let message = `String "Repeated type variable in type" in
    let loc = Location.to_yojson t.location in
    let content = `Assoc [
      ("message", message);
      ("location", loc);
    ] in
    json_error ~stage ~content
  | `Self_ast_imperative_non_linear_row t ->
    let message = `String "Duplicated field or variant name" in
    let loc = Location.to_yojson t.location in
    let content = `Assoc [
      ("message", message);
      ("location", loc);
    ] in
    json_error ~stage ~content
  | `Self_ast_imperative_duplicate_parameter exp ->
    let message = `String "Duplicated variable name in function parameter" in
    let loc = Location.to_yojson exp.location in
    let content = `Assoc [
      ("message", message);
      ("location", loc);
    ] in
    json_error ~stage ~content
  | `Self_ast_imperative_long_constructor (c,e) ->
    let message = `String "too long constructor (limited to 32)" in
    let loc = `String (Format.asprintf "%a" Location.pp e.location) in
    let content = `Assoc [
      ("message", message);
      ("location", loc);
      ("value", `String c)
    ] in
    json_error ~stage ~content
  | `Self_ast_imperative_bad_timestamp (t,e) ->
    let message = `String "badly formatted timestamp" in
    let loc = `String (Format.asprintf "%a" Location.pp e.location) in
    let content = `Assoc [
      ("message", message);
      ("location", loc);
      ("value", `String t)
    ] in
    json_error ~stage ~content
  | `Self_ast_imperative_bad_format_literal e ->
    let message = `String "badly formatted literal" in
    let loc = `String (Format.asprintf "%a" Location.pp e.location) in
    let content = `Assoc [
      ("message", message);
      ("location", loc);
    ] in
    json_error ~stage ~content
  | `Self_ast_imperative_bad_empty_arity (c, e) ->
    let message = `String "constant expects no parameters" in
    let loc = `String (Format.asprintf "%a" Location.pp e.location) in
    let value = `String (Format.asprintf "%a" PP.constant' c) in
    let content = `Assoc [
      ("message", message);
      ("location", loc);
      ("value", value);
    ] in
    json_error ~stage ~content
  | `Self_ast_imperative_bad_single_arity (c, e) ->
    let message = `String "constant expects one parameters" in
    let loc = `String (Format.asprintf "%a" Location.pp e.location) in
    let value = `String (Format.asprintf "%a" PP.constant' c) in
    let content = `Assoc [
      ("message", message);
      ("location", loc);
      ("value", value);
    ] in
    json_error ~stage ~content
  | `Self_ast_imperative_bad_map_param_type (c,e) ->
    let message = `String "constant expects a list of pair as parameter" in
    let loc = `String (Format.asprintf "%a" Location.pp e.location) in
    let value = `String (Format.asprintf "%a" PP.constant' c) in
    let content = `Assoc [
      ("message", message);
      ("location", loc);
      ("value", value);
    ] in
    json_error ~stage ~content
  | `Self_ast_imperative_bad_set_param_type (c,e) ->
    let message = `String "constant expects a list as parameter" in
    let loc = `String (Format.asprintf "%a" Location.pp e.location) in
    let value = `String (Format.asprintf "%a" PP.constant' c) in
    let content = `Assoc [
      ("message", message);
      ("location", loc);
      ("value", value);
    ] in
    json_error ~stage ~content
  | `Self_ast_imperative_bad_conversion_bytes e ->
    let message = `String "Bad bytes literal (conversion went wrong)" in
    let loc = `String (Format.asprintf "%a" Location.pp e.location) in
    let content = `Assoc [
      ("message", message);
      ("location", loc);
    ] in
    json_error ~stage ~content
  | `Self_ast_imperative_vars_captured vars ->
     let message = `String "Invalid capture: declared as a non-constant variable" in
     let loc ((loc, _v) : location * expression_variable) =
       `String (Format.asprintf "%a" Location.pp loc) in
     let locs = `List (List.map ~f:loc vars) in
     let content = `Assoc [
                       ("message", message);
                       ("locations", locs);
                     ] in
     json_error ~stage ~content
  | `Self_ast_imperative_const_assigned (loc, _var) ->
     let message = `String "Invalid assignment: declared as a constant variable" in
     let loc = `String (Format.asprintf "%a" Location.pp loc) in
     let content = `Assoc [
                       ("message", message);
                       ("location", loc);
                     ] in
     json_error ~stage ~content
  | `Self_ast_imperative_no_shadowing l ->
    let message = `String "Cannot redeclare block-scoped variable." in
    let loc = `String (Format.asprintf "%a" Location.pp l) in
    let content = `Assoc [
                      ("message", message);
                      ("location", loc);
                    ] in
    json_error ~stage ~content
