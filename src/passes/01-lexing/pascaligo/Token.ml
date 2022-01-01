(* Token specification for PascaLIGO *)

(* Vendor dependencies *)

module Region    = Simple_utils.Region
module Markup    = LexerLib.Markup
module Directive = LexerLib.Directive

(* Utility modules and types *)

module SMap = Simple_utils.Map.Make (String)
module Wrap = Lexing_shared.Wrap

type 'a wrap = 'a Wrap.t
type 'a reg  = 'a Region.reg

let wrap = Wrap.wrap

(* TOKENS *)

type lexeme = Lexing_shared.Common.lexeme

module T =
  struct
    (* Tokens *)

    (* Definition of tokens generated by menhir --only-tokens *)
    (*   It contains [token] and ['a terminal] types. The first one we
         redefine manually here (by type [t]) but the second one we need to
         satisfy Menhir's Inspection API.  *)

    include Menhir_pascaligo_tokens.MenhirToken

    type t =
      (* Preprocessing directives *)

      Directive of Directive.t

      (* Literals *)

    | String   of lexeme wrap
    | Verbatim of lexeme wrap
    | Bytes    of (lexeme * Hex.t) wrap
    | Int      of (lexeme * Z.t) wrap
    | Nat      of (lexeme * Z.t) wrap
    | Mutez    of (lexeme * Z.t) wrap
    | Ident    of lexeme wrap
    | UIdent   of lexeme wrap
    | Lang     of lexeme reg reg
    | Attr     of string wrap

    (* Symbols *)

    | SEMI     of lexeme wrap  (* ";"   *)
    | COMMA    of lexeme wrap  (* ","   *)
    | LPAR     of lexeme wrap  (* "("   *)
    | RPAR     of lexeme wrap  (* ")"   *)
    | LBRACE   of lexeme wrap  (* "{"   *)
    | RBRACE   of lexeme wrap  (* "}"   *)
    | LBRACKET of lexeme wrap  (* "["   *)
    | RBRACKET of lexeme wrap  (* "]"   *)
    | CONS     of lexeme wrap  (* "#"   *)
    | VBAR     of lexeme wrap  (* "|"   *)
    | ARROW    of lexeme wrap  (* "->"  *)
    | ASS      of lexeme wrap  (* ":="  *)
    | EQ       of lexeme wrap  (* "="   *)
    | COLON    of lexeme wrap  (* ":"   *)
    | LT       of lexeme wrap  (* "<"   *)
    | LE       of lexeme wrap  (* "<="  *)
    | GT       of lexeme wrap  (* ">"   *)
    | GE       of lexeme wrap  (* ">="  *)
    | NE       of lexeme wrap  (* "=/=" *)
    | PLUS     of lexeme wrap  (* "+"   *)
    | MINUS    of lexeme wrap  (* "-"   *)
    | SLASH    of lexeme wrap  (* "/"   *)
    | TIMES    of lexeme wrap  (* "*"   *)
    | DOT      of lexeme wrap  (* "."   *)
    | WILD     of lexeme wrap  (* "_"   *)
    | CARET    of lexeme wrap  (* "^"   *)

    (* Keywords *)

    | And        of lexeme wrap  (* and       *)
    | Begin      of lexeme wrap  (* begin     *)
    | BigMap     of lexeme wrap  (* big_map   *)
    | Block      of lexeme wrap  (* block     *)
    | Case       of lexeme wrap  (* case      *)
    | Const      of lexeme wrap  (* const     *)
    | Contains   of lexeme wrap  (* contains  *)
    | Else       of lexeme wrap  (* else      *)
    | End        of lexeme wrap  (* end       *)
    | For        of lexeme wrap  (* for       *)
    | From       of lexeme wrap  (* from      *)
    | Function   of lexeme wrap  (* function  *)
    | Recursive  of lexeme wrap  (* recursive *)
    | If         of lexeme wrap  (* if        *)
    | In         of lexeme wrap  (* in        *)
    | Is         of lexeme wrap  (* is        *)
    | List       of lexeme wrap  (* list      *)
    | Map        of lexeme wrap  (* map       *)
    | Mod        of lexeme wrap  (* mod       *)
    | Nil        of lexeme wrap  (* nil       *)
    | Not        of lexeme wrap  (* not       *)
    | Of         of lexeme wrap  (* of        *)
    | Or         of lexeme wrap  (* or        *)
    | Patch      of lexeme wrap  (* patch     *)
    | Record     of lexeme wrap  (* record    *)
    | Remove     of lexeme wrap  (* remove    *)
    | Set        of lexeme wrap  (* set       *)
    | Skip       of lexeme wrap  (* skip      *)
    | Step       of lexeme wrap  (* step      *)
    | Then       of lexeme wrap  (* then      *)
    | To         of lexeme wrap  (* to        *)
    | Type       of lexeme wrap  (* type      *)
    | Var        of lexeme wrap  (* var       *)
    | While      of lexeme wrap  (* while     *)
    | With       of lexeme wrap  (* with      *)
    | Module     of lexeme wrap  (* module    *)

    (* End-Of-File *)

    | EOF of lexeme wrap

    (* Unlexing the tokens *)

    let gen_sym prefix =
      let count = ref 0 in
      fun () -> incr count; prefix ^ string_of_int !count

    let id_sym   = gen_sym "id"
    and ctor_sym = gen_sym "C"

    let concrete = function
      (* Literals *)

      "Ident"    -> id_sym ()
    | "UIdent"   -> ctor_sym ()
    | "Int"      -> "1"
    | "Nat"      -> "1n"
    | "Mutez"    -> "1mutez"
    | "String"   -> "\"a string\""
    | "Verbatim" -> "{|verbatim|}"
    | "Bytes"    -> "0xAA"
    | "Attr"     -> "[@attr]"
    | "Lang"     -> "[%Michelson"

    (* Symbols *)

    | "SEMI"     -> ";"
    | "COMMA"    -> ","
    | "LPAR"     -> "("
    | "RPAR"     -> ")"
    | "LBRACE"   -> "{"
    | "RBRACE"   -> "}"
    | "LBRACKET" -> "["
    | "RBRACKET" -> "]"
    | "CONS"     -> "#"
    | "VBAR"     -> "|"
    | "ARROW"    -> "->"
    | "ASS"      -> ":="
    | "EQ"       -> "="
    | "COLON"    -> ":"
    | "LT"       -> "<"
    | "LE"       -> "<="
    | "GT"       -> ">"
    | "GE"       -> ">="
    | "NE"       -> "=/="
    | "PLUS"     -> "+"
    | "MINUS"    -> "-"
    | "SLASH"    -> "/"
    | "TIMES"    -> "*"
    | "DOT"      -> "."
    | "WILD"     -> "_"
    | "CARET"    -> "^"

    (* Keywords *)

    | "And"       -> "and"
    | "Begin"     -> "begin"
    | "BigMap"    -> "big_map"
    | "Block"     ->  "block"
    | "Case"      -> "case"
    | "Const"     -> "const"
    | "Contains"  -> "contains"
    | "Else"      -> "else"
    | "End"       -> "end"
    | "For"       -> "for"
    | "From"      -> "from"
    | "Function"  -> "function"
    | "Recursive" -> "recursive"
    | "If"        -> "if"
    | "In"        -> "in"
    | "Is"        -> "is"
    | "List"      -> "list"
    | "Map"       -> "map"
    | "Mod"       -> "mod"
    | "Nil"       -> "nil"
    | "Not"       -> "not"
    | "Of"        -> "of"
    | "Or"        -> "or"
    | "Patch"     -> "patch"
    | "Record"    -> "record"
    | "Remove"    -> "remove"
    | "Set"       -> "set"
    | "Skip"      -> "skip"
    | "Step"      -> "step"
    | "Then"      -> "then"
    | "To"        -> "to"
    | "Type"      -> "type"
    | "Var"       -> "var"
    | "While"     -> "while"
    | "With"      -> "with"
    | "Module"    -> "module"

    (* End-Of-File *)

    | "EOF" -> ""

    (* This case should not happen! *)

    | _  -> "\\Unknown" (* Backslash meant to trigger an error *)


    (* Projections *)

    let sprintf = Printf.sprintf

    type token = t

    let proj_token = function
        (* Preprocessing directives *)

      Directive d ->
        Directive.project d

      (* Literals *)

    | String t ->
        t#region, sprintf "String %S" t#payload
    | Verbatim t ->
        t#region, sprintf "Verbatim %S" t#payload
    | Bytes t ->
        let (s,b) = t#payload in
        t#region,
        sprintf "Bytes (%S, \"0x%s\")" s (Hex.show b)
    | Int t ->
        let (s, n) = t#payload in
        t#region, sprintf "Int (%S, %s)" s (Z.to_string n)
    | Nat t ->
        let (s, n) = t#payload in
        t#region, sprintf "Nat (%S, %s)" s (Z.to_string n)
    | Mutez t ->
        let (s, n) = t#payload in
        t#region, sprintf "Mutez (%S, %s)" s (Z.to_string n)
    | Ident t ->
        t#region, sprintf "Ident %S" t#payload
    | UIdent t ->
        t#region, sprintf "UIdent %S" t#payload
    | Attr t ->
        t#region, sprintf "Attr %S" t#payload
    | Lang {value = {value = payload; _}; region; _} ->
        region, sprintf "Lang %S" payload

    (* Symbols *)

    | SEMI     t -> t#region, "SEMI"
    | COMMA    t -> t#region, "COMMA"
    | LPAR     t -> t#region, "LPAR"
    | RPAR     t -> t#region, "RPAR"
    | LBRACE   t -> t#region, "LBRACE"
    | RBRACE   t -> t#region, "RBRACE"
    | LBRACKET t -> t#region, "LBRACKET"
    | RBRACKET t -> t#region, "RBRACKET"
    | CONS     t -> t#region, "CONS"
    | VBAR     t -> t#region, "VBAR"
    | ARROW    t -> t#region, "ARROW"
    | ASS      t -> t#region, "ASS"
    | EQ       t -> t#region, "EQ"
    | COLON    t -> t#region, "COLON"
    | LT       t -> t#region, "LT"
    | LE       t -> t#region, "LE"
    | GT       t -> t#region, "GT"
    | GE       t -> t#region, "GE"
    | NE       t -> t#region, "NE"
    | PLUS     t -> t#region, "PLUS"
    | MINUS    t -> t#region, "MINUS"
    | SLASH    t -> t#region, "SLASH"
    | TIMES    t -> t#region, "TIMES"
    | DOT      t -> t#region, "DOT"
    | WILD     t -> t#region, "WILD"
    | CARET    t -> t#region, "CARET"

    (* Keywords *)

    | And       t -> t#region, "And"
    | Begin     t -> t#region, "Begin"
    | BigMap    t -> t#region, "BigMap"
    | Block     t -> t#region, "Block"
    | Case      t -> t#region, "Case"
    | Const     t -> t#region, "Const"
    | Contains  t -> t#region, "Contains"
    | Else      t -> t#region, "Else"
    | End       t -> t#region, "End"
    | For       t -> t#region, "For"
    | From      t -> t#region, "From"
    | Function  t -> t#region, "Function"
    | Recursive t -> t#region, "Recursive"
    | If        t -> t#region, "If"
    | In        t -> t#region, "In"
    | Is        t -> t#region, "Is"
    | List      t -> t#region, "List"
    | Map       t -> t#region, "Map"
    | Mod       t -> t#region, "Mod"
    | Nil       t -> t#region, "Nil"
    | Not       t -> t#region, "Not"
    | Of        t -> t#region, "Of"
    | Or        t -> t#region, "Or"
    | Patch     t -> t#region, "Patch"
    | Record    t -> t#region, "Record"
    | Remove    t -> t#region, "Remove"
    | Set       t -> t#region, "Set"
    | Skip      t -> t#region, "Skip"
    | Step      t -> t#region, "Step"
    | Then      t -> t#region, "Then"
    | To        t -> t#region, "To"
    | Type      t -> t#region, "Type"
    | Var       t -> t#region, "Var"
    | While     t -> t#region, "While"
    | With      t -> t#region, "With"
    | Module    t -> t#region, "Module"

    (* End-Of-File *)

    | EOF t -> t#region, "EOF"

    let to_lexeme = function
      (* Directives *)

      Directive d -> Directive.to_lexeme d

      (* Literals *)

    | String t   -> sprintf "%S" (String.escaped t#payload)
    | Verbatim t -> String.escaped t#payload
    | Bytes t    -> fst t#payload
    | Int t
    | Nat t
    | Mutez t    -> fst t#payload
    | Ident t
    | UIdent t   -> t#payload
    | Attr t     -> t#payload
    | Lang lang  -> Region.(lang.value.value)

    (* Symbols *)

    | SEMI     _ -> ";"
    | COMMA    _ -> ","
    | LPAR     _ -> "("
    | RPAR     _ -> ")"
    | LBRACE   _ -> "{"
    | RBRACE   _ -> "}"
    | LBRACKET _ -> "["
    | RBRACKET _ -> "]"
    | CONS     _ -> "#"
    | VBAR     _ -> "|"
    | ARROW    _ -> "->"
    | ASS      _ -> ":="
    | EQ       _ -> "="
    | COLON    _ -> ":"
    | LT       _ -> "<"
    | LE       _ -> "<="
    | GT       _ -> ">"
    | GE       _ -> ">="
    | NE       _ -> "=/="
    | PLUS     _ -> "+"
    | MINUS    _ -> "-"
    | SLASH    _ -> "/"
    | TIMES    _ -> "*"
    | DOT      _ -> "."
    | WILD     _ -> "_"
    | CARET    _ -> "^"

    (* Keywords *)

    | And       _ -> "and"
    | Begin     _ -> "begin"
    | BigMap    _ -> "big_map"
    | Block     _ -> "block"
    | Case      _ -> "case"
    | Const     _ -> "const"
    | Contains  _ -> "contains"
    | Else      _ -> "else"
    | End       _ -> "end"
    | For       _ -> "for"
    | From      _ -> "from"
    | Function  _ -> "function"
    | Recursive _ -> "recursive"
    | If        _ -> "if"
    | In        _ -> "in"
    | Is        _ -> "is"
    | List      _ -> "list"
    | Map       _ -> "map"
    | Mod       _ -> "mod"
    | Nil       _ -> "nil"
    | Not       _ -> "not"
    | Of        _ -> "of"
    | Or        _ -> "or"
    | Patch     _ -> "patch"
    | Record    _ -> "record"
    | Remove    _ -> "remove"
    | Set       _ -> "set"
    | Skip      _ -> "skip"
    | Step      _ -> "step"
    | Then      _ -> "then"
    | To        _ -> "to"
    | Type      _ -> "type"
    | Var       _ -> "var"
    | While     _ -> "while"
    | With      _ -> "with"
    | Module    _ -> "module"

    (* End-Of-File *)

    | EOF _ -> ""


    (* CONVERSIONS *)

    let to_string ~offsets mode token =
      let region, val_str = proj_token token in
      let reg_str = region#compact ~offsets mode
      in sprintf "%s: %s" reg_str val_str

    let to_region token = proj_token token |> fst

    (* SMART CONSTRUCTORS *)

    (* Keywords *)

    let keywords = [
      (fun reg -> And       (wrap "And"       reg));
      (fun reg -> Begin     (wrap "Begin"     reg));
      (fun reg -> BigMap    (wrap "BigMap"    reg));
      (fun reg -> Block     (wrap "Block"     reg));
      (fun reg -> Case      (wrap "Case"      reg));
      (fun reg -> Const     (wrap "Const"     reg));
      (fun reg -> Contains  (wrap "Contains"  reg));
      (fun reg -> Else      (wrap "Else"      reg));
      (fun reg -> End       (wrap "End"       reg));
      (fun reg -> For       (wrap "For"       reg));
      (fun reg -> From      (wrap "From"      reg));
      (fun reg -> Function  (wrap "Function"  reg));
      (fun reg -> If        (wrap "If"        reg));
      (fun reg -> In        (wrap "In"        reg));
      (fun reg -> Is        (wrap "Is"        reg));
      (fun reg -> List      (wrap "List"      reg));
      (fun reg -> Map       (wrap "Map"       reg));
      (fun reg -> Mod       (wrap "Mod"       reg));
      (fun reg -> Nil       (wrap "Nil"       reg));
      (fun reg -> Not       (wrap "Not"       reg));
      (fun reg -> Of        (wrap "Of"        reg));
      (fun reg -> Or        (wrap "Or"        reg));
      (fun reg -> Patch     (wrap "Patch"     reg));
      (fun reg -> Record    (wrap "Record"    reg));
      (fun reg -> Recursive (wrap "Recursive" reg));
      (fun reg -> Remove    (wrap "Remove"    reg));
      (fun reg -> Set       (wrap "Set"       reg));
      (fun reg -> Skip      (wrap "Skip"      reg));
      (fun reg -> Step      (wrap "Step"      reg));
      (fun reg -> Then      (wrap "Then"      reg));
      (fun reg -> To        (wrap "To"        reg));
      (fun reg -> Type      (wrap "Type"      reg));
      (fun reg -> Var       (wrap "Var"       reg));
      (fun reg -> While     (wrap "While"     reg));
      (fun reg -> With      (wrap "With"      reg));
      (fun reg -> Module    (wrap "Module"    reg))
    ]

    let keywords =
      let add map (key, value) = SMap.add key value map in
      let apply map mk_kwd =
        add map (to_lexeme (mk_kwd Region.ghost), mk_kwd)
      in List.fold_left ~f:apply ~init:SMap.empty keywords

    type kwd_err = Invalid_keyword

    let mk_kwd ident region =
      try let mk_kwd = SMap.find ident keywords in Ok (mk_kwd region) with
      |        _ -> Error Invalid_keyword

    (* Strings *)

    let mk_string lexeme region = String (wrap lexeme region)

    let mk_verbatim lexeme region = Verbatim (wrap lexeme region)

    (* Bytes *)

    let mk_bytes lexeme region =
      let norm = Str.(global_replace (regexp "_") "" lexeme) in
      let value = lexeme, `Hex norm
      in Bytes (wrap value region)

    (* Numerical values *)

    type int_err = Non_canonical_zero

    let mk_int lexeme region =
      let z =
        Str.(global_replace (regexp "_") "" lexeme) |> Z.of_string
      in if   Z.equal z Z.zero && Base.String.(<>) lexeme "0"
         then Error Non_canonical_zero
         else Ok (Int (wrap (lexeme, z) region))

    type nat_err =
      Invalid_natural
    | Unsupported_nat_syntax
    | Non_canonical_zero_nat

    let mk_nat lexeme region =
      match String.index_opt lexeme 'n' with
        None -> Error Invalid_natural
      | Some _ ->
          let z =
            Str.(global_replace (regexp "_") "" lexeme) |>
              Str.(global_replace (regexp "n") "") |>
              Z.of_string in
          if   Z.equal z Z.zero && Base.String.(<>) lexeme "0n"
          then Error Non_canonical_zero_nat
          else Ok (Nat (wrap (lexeme, z) region))

    type mutez_err =
      Unsupported_mutez_syntax
    | Non_canonical_zero_tez

    let mk_mutez lexeme region =
      let z = Str.(global_replace (regexp "_") "" lexeme) |>
                Str.(global_replace (regexp "mutez") "") |>
                Z.of_string in
      if   Z.equal z Z.zero && Base.String.(<>) lexeme "0mutez"
      then Error Non_canonical_zero_tez
      else Ok (Mutez (wrap (lexeme, z) region))

    (* End-Of-File *)

    let mk_eof region = EOF (wrap "" region)

    (* Symbols *)

    type sym_err = Invalid_symbol of string

    let mk_sym lexeme region =
      match lexeme with
        (* Lexemes in common with all concrete syntaxes *)

        ";"   -> Ok (SEMI     (wrap lexeme region))
      | ","   -> Ok (COMMA    (wrap lexeme region))
      | "("   -> Ok (LPAR     (wrap lexeme region))
      | ")"   -> Ok (RPAR     (wrap lexeme region))
      | "["   -> Ok (LBRACKET (wrap lexeme region))
      | "]"   -> Ok (RBRACKET (wrap lexeme region))
      | "{"   -> Ok (LBRACE   (wrap lexeme region))
      | "}"   -> Ok (RBRACE   (wrap lexeme region))
      | "="   -> Ok (EQ       (wrap lexeme region))
      | ":"   -> Ok (COLON    (wrap lexeme region))
      | "|"   -> Ok (VBAR     (wrap lexeme region))
      | "."   -> Ok (DOT      (wrap lexeme region))
      | "_"   -> Ok (WILD     (wrap lexeme region))
      | "+"   -> Ok (PLUS     (wrap lexeme region))
      | "-"   -> Ok (MINUS    (wrap lexeme region))
      | "*"   -> Ok (TIMES    (wrap lexeme region))
      | "/"   -> Ok (SLASH    (wrap lexeme region))
      | "<"   -> Ok (LT       (wrap lexeme region))
      | "<="  -> Ok (LE       (wrap lexeme region))
      | ">"   -> Ok (GT       (wrap lexeme region))
      | ">="  -> Ok (GE       (wrap lexeme region))

      (* Lexemes specific to PascaLIGO *)

      | "^"   -> Ok (CARET    (wrap lexeme region))
      | "->"  -> Ok (ARROW    (wrap lexeme region))
      | "=/=" -> Ok (NE       (wrap lexeme region))
      | "#"   -> Ok (CONS     (wrap lexeme region))
      | ":="  -> Ok (ASS      (wrap lexeme region))

      (* Invalid symbols *)

      | s ->  Error (Invalid_symbol s)

    (* Identifiers *)

    let mk_ident value region =
      match SMap.find_opt value keywords with
        Some mk_kwd -> mk_kwd region
      |        None -> Ident (wrap value region)

    (* Constructors/Modules *)

    let mk_uident value region = UIdent (wrap value region)

    (* Attributes *)

    let mk_attr lexeme region = Attr (wrap lexeme region)

    (* Code injection *)

    type lang_err = Unsupported_lang_syntax

    let mk_lang lang region = Ok (Lang Region.{value=lang; region})

    (* PREDICATES *)

    let is_eof = function EOF _ -> true | _ -> false

    let support_string_delimiter c = (Char.equal c '"')

    let verbatim_delimiters = ("{|", "|}")
  end

include T

module type S = module type of T
