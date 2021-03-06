open Test_helpers
module Trace = Simple_utils.Trace
open Simple_utils.Trace
open Main_errors

type ('a,'err) sdata = {
  erroneous_source_file : string ;
  preproc : raise:'err raise -> string -> Buffer.t * (string * string) list;
  parser  : add_warning:(Main_warnings.all -> unit) -> raise:'err raise -> Buffer.t -> 'a
}

let pascaligo_sdata = {
  erroneous_source_file =
    "../passes/02-parsing/pascaligo/all.ligo" ;
  preproc =
    (fun ~raise s -> trace ~raise preproc_tracer @@
    fun ~raise -> Trace.from_result ~raise @@
    Preprocessing.Pascaligo.preprocess_string [] s);
  parser =
    fun ~add_warning ~raise buffer -> trace ~raise parser_tracer @@
      Parsing.Pascaligo.parse_expression buffer ~add_warning
}

let cameligo_sdata = {
  erroneous_source_file =
    "../passes/02-parsing/cameligo/all.mligo";
  preproc =
    (fun ~raise s -> trace ~raise preproc_tracer @@
    fun ~raise -> Trace.from_result ~raise @@
    Preprocessing.Cameligo.preprocess_string [] s);
  parser =
    fun ~add_warning ~raise buffer -> trace ~raise parser_tracer @@
      Parsing.Cameligo.parse_expression buffer ~add_warning
}

let reasonligo_sdata = {
  erroneous_source_file =
    "../passes/02-parsing/reasonligo/all.religo" ;
  preproc =
    (fun ~raise s -> trace ~raise preproc_tracer @@
    fun ~raise -> Trace.from_result ~raise @@
    Preprocessing.Reasonligo.preprocess_string [] s);
  parser =
    fun ~add_warning ~raise buffer -> trace ~raise parser_tracer @@
      Parsing.Reasonligo.parse_expression buffer ~add_warning
}

let get_exp_as_string filename =
  let lines = ref [] in
  let chan = In_channel.create filename in
  try
    while true; do
      lines := In_channel.input_line_exn chan :: !lines
    done; !lines
  with End_of_file ->
    In_channel.close chan;
    List.rev !lines

let assert_syntax_error ~raise ~add_warning sdata () =
  let aux entry =
    Format.printf "Entry : <%s>%!\n" entry ;
    let c_unit,_ = sdata.preproc ~raise entry in
    Assert.assert_fail ~raise (test_internal __LOC__) @@
      sdata.parser ~add_warning c_unit;
    Format.printf "Parsed%!\n" ;
    ()
  in
  let exps = get_exp_as_string sdata.erroneous_source_file in
  List.iter ~f:aux exps


let () =
  Printexc.record_backtrace true ;
  run_test @@ test_suite "LIGO" [
    test_suite "Parser negative tests" [
      test_w "pascaligo"  @@ assert_syntax_error pascaligo_sdata ;
      test_w "cameligo"   @@ assert_syntax_error cameligo_sdata ;
      test_w "reasonligo" @@ assert_syntax_error reasonligo_sdata ;
    ]
  ] ;
  ()
