(**

This implements the pattern_matching compiler of `Peyton-Jones, S.L., The Implementation of Functional Programming Languages`, chapter 5.
By reduction, this algorithm transforms pattern matching expression into (nested) cases expressions.
`Sugar` match expression being 'pattern matching' expression and `Core`/`Typed` being 'case expressions'.

"Product patterns" (e.g. tuple & record) are considered variables, an extra rule (product_rule) handles them

List patterns are treated as the variant type `NIL | Cons of (hd , tl)` would be.
Option patterns are treated as the variant type `Some a | None` would be

**)

module I = Ast_core
module O = Ast_typed
module Ligo_string = Simple_utils.Ligo_string

open Simple_utils.Trace
open Errors

type matchees = O.expression_variable list
type pattern = O.type_expression O.pattern
type typed_pattern = pattern * O.type_expression
type equations = (typed_pattern list * O.expression) list
type rest = O.expression_content

module PP_DEBUG = struct
  let pp_typed_pattern ppf ((p,t) : typed_pattern) = Format.fprintf ppf "(%a : %a)" (Stage_common.PP.match_pattern O.PP.type_expression) p O.PP.type_expression t
  let pp_pattern_list ppf (plist : typed_pattern list) = Format.fprintf ppf "[%a]" Simple_utils.PP_helpers.(list_sep pp_typed_pattern (tag "; ")) plist
  let pp_eq ppf ((plist,expr):(typed_pattern list * O.expression)) = Format.fprintf ppf "@[%a -> %a]" pp_pattern_list plist O.PP.expression expr
  let pp_eqs ppf (eqs:equations) = Format.fprintf ppf "@[<hv>%a@]" Simple_utils.PP_helpers.(list_sep pp_eq (tag "; ")) eqs
  let pp_partition ppf (part: equations list) = Format.fprintf ppf "@[<hv><@.%a@.>@]" Simple_utils.PP_helpers.(list_sep pp_eqs (tag "@.")) part
end

let is_var : _ I.pattern -> bool = fun p ->
  match p.wrap_content with
  | P_var _ -> true
  | P_tuple _ -> true
  | P_record _ -> true
  | P_unit -> true
  | _ -> false
let is_product' : _ I.pattern -> bool = fun p ->
  match p.wrap_content with
  | P_tuple _ -> true
  | P_record _ -> true
  | _ -> false

let is_product : equations -> typed_pattern option = fun eqs ->
  List.find_map
    ~f:(fun (pl,_) ->
      match pl with
      | (p,t)::_ -> if is_product' p then Some(p,t) else None
      | [] -> None
    )
    eqs

let corner_case loc = (corner_case ("broken invariant at "^loc))

let get_pattern_type ~raise (eqs : equations) =
  match eqs with
    (((_,t)::_),_)::_ -> t
  | (([],_)::_) -> raise.raise @@ corner_case __LOC__ (* typed_pattern list empty *)
  | [] -> raise.raise @@ corner_case __LOC__ (* equations empty *)

let get_body_type ~raise (eqs : equations) =
  match eqs with
    (_,e)::_ -> e.type_expression
  | [] -> raise.raise @@ corner_case __LOC__ (* equations empty *)

let extract_variant_type ~raise : pattern -> O.label -> O.type_expression -> O.type_expression =
  fun _ label t ->
  match t.type_content with
  | T_sum rows -> (
    match O.LMap.find_opt label rows.content with
    | Some t -> t.associated_type
    | None -> raise.raise @@ corner_case __LOC__
  )
  | O.T_constant { injection = Stage_common.Constant.List ; parameters = [proj_t] ; language=_} -> (
    match label with
    | Label "Cons" -> O.make_t_ez_record [("0",proj_t);("1",t)]
    | Label "Nil" -> (O.t_unit ())
    | Label _ -> raise.raise @@ corner_case __LOC__
  )
  | _ -> raise.raise @@ corner_case __LOC__

let extract_record_type ~raise : pattern -> O.label -> O.type_expression -> O.type_expression =
  fun _ label t ->
  match t.type_content with
  | T_record rows -> (
    match O.LMap.find_opt label rows.content with
    | Some t -> t.associated_type
    | None -> raise.raise @@ corner_case __LOC__
  )
  | _ -> raise.raise @@ corner_case __LOC__

(**
  `substitute_var_in_body to_subst new_var body` replaces variables equal to `to_subst` with variable `new_var` in expression `body`.
  note that `new_var` here is never a user variable (always previously generated by the compiler)
**)
let rec substitute_var_in_body ~raise : O.expression_variable -> O.expression_variable -> O.expression -> O.expression =
  fun to_subst new_var body -> 
    let aux ~raise : unit -> O.expression -> bool * unit * O.expression =
      fun () exp ->
        let ret continue exp = (continue,(),exp) in
        match exp.expression_content with
        | O.E_variable var when I.ValueVar.equal var to_subst ->
          ret true { exp with expression_content = E_variable new_var }
        | O.E_let_in letin when I.ValueVar.equal letin.let_binder.var to_subst ->
          let rhs = substitute_var_in_body ~raise to_subst new_var letin.rhs in
          let letin = { letin with rhs } in
          ret false { exp with expression_content = E_let_in letin}
        | O.E_assign assign when I.ValueVar.equal assign.binder.var to_subst ->
          let expression = substitute_var_in_body ~raise to_subst new_var assign.expression in
          let assign = { assign with expression } in
          ret false { exp with expression_content = E_assign assign}
        | O.E_lambda lamb when I.ValueVar.equal lamb.binder.var to_subst -> ret false exp
        | O.E_recursive r when I.ValueVar.equal r.fun_name to_subst -> ret false exp
        | O.E_matching m -> (
          let matchee = substitute_var_in_body ~raise to_subst new_var m.matchee in
          let cases = match m.cases with 
          | Match_record {fields;body;tv} -> 
            if O.LMap.exists (fun _ ((v : O.type_expression O.binder)) -> I.ValueVar.equal v.var to_subst) fields 
            then m.cases 
            else
              let body = substitute_var_in_body ~raise to_subst new_var body in
              Match_record {fields;body;tv}
          | Match_variant {cases;tv} ->
            let cases = List.fold_right cases ~init:[] ~f:(fun case cases -> 
              if I.ValueVar.equal case.pattern to_subst then case::cases
              else
                let body = substitute_var_in_body ~raise to_subst new_var case.body in
                {case with body}::cases
            )in
            Match_variant {cases;tv}
          in
          ret false { exp with expression_content = O.E_matching {matchee ; cases}}
        )
        | (E_literal _ | E_constant _ | E_variable _ | E_application _ | E_lambda _ |
           E_type_abstraction _|E_recursive _|E_let_in _| E_mod_in _ |
           E_raw_code _ | E_constructor _ | E_record _ | E_record_accessor _ |
           E_record_update _ | E_type_inst _ | E_module_accessor _ | E_assign _) -> ret true exp
    in
    let ((), res) = O.Helpers.fold_map_expression (aux ~raise) () body in
    res

let make_var_pattern : O.expression_variable -> pattern =
  fun var -> Location.wrap @@ O.P_var { var ; ascr = None ; attributes = Stage_common.Helpers.empty_attribute }

let rec partition : ('a -> bool) -> 'a list -> 'a list list =
  fun f lst ->
    let add_inner x ll =
      match ll with
      | hdl::tll -> (x::hdl)::tll
      | _ -> assert false
    in
    match lst with
    | [] -> []
    | [x] -> [[x]]
    | x::x'::tl ->
      if Bool.(=) (f x) (f x') then add_inner x (partition f (x'::tl))
      else [x] :: (partition f (x'::tl))

(**
  groups together equations that begin with the same constructor
**)
let group_equations ~raise : equations -> equations O.label_map =
  fun eqs ->
    let aux : typed_pattern list * O.expression -> equations O.label_map -> equations O.label_map =
      fun (pl , body) m ->
        let (phd,t) = List.hd_exn pl in
        let ptl = List.tl_exn pl in
        let upd : O.type_expression -> pattern -> equations option -> equations option =
          fun proj_t pattern kopt ->
            match kopt with
            | Some eqs ->
              let p = (pattern,proj_t) in
              Some (( p::ptl , body)::eqs)
            | None ->
              let p = (pattern,proj_t) in
              Some [ (p::ptl          , body) ]
        in
        match phd.wrap_content with
        | P_variant (label,p_opt) ->
          let proj_t = extract_variant_type ~raise phd label t in
          O.LMap.update label (upd proj_t p_opt) m
        | P_list (List []) ->
          let label = O.Label "Nil" in
          let proj_t = extract_variant_type ~raise phd label t in
          O.LMap.update label (upd proj_t (Location.wrap O.P_unit)) m
        | P_list (Cons (p_hd,p_tl)) ->
          let label = O.Label "Cons" in
          let pattern = Location.wrap ~loc:(phd.location) @@ I.P_tuple [p_hd;p_tl] in
          let proj_t = extract_variant_type ~raise phd label t in
          O.LMap.update label (upd proj_t pattern) m
        | _ -> raise.raise @@ corner_case __LOC__
    in
    List.fold_right ~f:aux ~init:O.LMap.empty eqs

let rec match_ ~raise : err_loc:Location.t -> matchees -> equations -> rest -> O.expression =
  fun ~err_loc ms eqs def ->
  match ms , eqs with
  | [] , [([],body)] -> body
  | [] , eqs when List.for_all ~f:(fun (ps,_) -> List.length ps = 0) eqs ->
    raise.raise @@ redundant_pattern err_loc
  | _ ->
    let leq = partition (fun (pl,_) -> is_var (fst @@ List.hd_exn pl)) eqs in
    let aux = fun (part_eq:equations) ((def,_,_):O.expression_content * O.type_expression option * Location.t) ->
      let r = consvar ~raise ~err_loc ms part_eq def in
      (r.expression_content , Some r.type_expression, r.location)
    in
    let (r,t,location) = List.fold_right ~f:aux ~init:(def,None,Location.generated) leq in
    O.make_e ~location r (Option.value_exn t)

and consvar ~raise : err_loc:Location.t -> matchees -> equations -> rest -> O.expression =
  fun ~err_loc ms eqs def ->
  let p1s = List.map ~f:(fun el -> fst @@ List.hd_exn @@ fst el) eqs in
    if List.for_all ~f:is_var p1s then
      let product_opt = is_product eqs in
      var_rule ~raise ~err_loc product_opt ms eqs def
    else
      ctor_rule ~raise ~err_loc ms eqs def

and var_rule ~raise : err_loc:Location.t -> typed_pattern option -> matchees -> equations -> rest -> O.expression =
  fun ~err_loc product_opt ms eqs def ->
  match ms with
  | mhd::mtl -> (
    match product_opt with
    | Some shape ->
      product_rule ~raise ~err_loc shape ms eqs def
    | None ->
       let aux : typed_pattern list * O.expression ->
                 (typed_pattern list * O.expression) =
        fun (pl, body) ->
        match pl with
        | (phd,_)::ptl -> (
          match phd.wrap_content with
          | P_var b ->
            let body' = substitute_var_in_body ~raise b.var mhd body in
            (ptl , body')
          | P_unit -> (ptl , body)
          |  _ -> raise.raise @@ corner_case __LOC__
        )
        | [] -> raise.raise @@ corner_case __LOC__
      in
      let eqs' = List.map ~f:aux eqs in
      match_ ~raise ~err_loc mtl eqs' def
  )
  | [] -> raise.raise @@ corner_case __LOC__

and ctor_rule ~raise : err_loc:Location.t -> matchees -> equations -> rest -> O.expression =
  fun ~err_loc ms eqs def ->
  match ms with
  | mhd::mtl ->
    let matchee_t = get_pattern_type ~raise eqs in
    let body_t = get_body_type ~raise eqs in
    let matchee = O.e_a_variable mhd matchee_t in
    let eq_map = group_equations ~raise eqs in
    let aux_p :  O.label * equations -> O.matching_content_case  =
      fun (constructor,eq) ->
        let proj =
          match eq with
          | [(tp,_)] -> (
            let (pattern,_) = List.hd_exn tp in
            match pattern.wrap_content with
            | P_var x -> x.var
            | P_unit -> I.ValueVar.fresh ~name:"unit_proj" ()
            | _ -> I.ValueVar.fresh ~name:"ctor_proj" ()
          )
          | _ ->
            I.ValueVar.fresh ~name:"ctor_proj" ()
        in
        let new_ms = proj::mtl in
        let nested = match_ ~raise ~err_loc new_ms eq def in
        O.{ constructor ; pattern = proj ; body = nested }
    in
    let aux_m : O.label * O.type_expression -> O.matching_content_case =
      fun (constructor,t) ->
        let proj = I.ValueVar.fresh ~name:"ctor_proj" () in
        let body = O.make_e def t in
        { constructor ; pattern = proj ; body }
    in
    let grouped_eqs =
      match O.get_t_sum matchee_t with
      | Some _ when Option.is_some (O.get_t_option matchee_t) ->
        List.map ~f:(fun label -> (label, O.LMap.find_opt label eq_map)) O.[Label "Some"; Label "None"]
      | Some rows ->
        let eq_opt_map = O.LMap.mapi (fun label _ -> O.LMap.find_opt label eq_map) rows.content in
        O.LMap.to_kv_list @@ eq_opt_map
      | None -> (
        (* REMITODO: parametric types in env ? *)
        match O.get_t_list matchee_t with
        | Some _ -> List.map ~f:(fun label -> (label, O.LMap.find_opt label eq_map)) O.[Label "Cons"; Label "Nil"]
        | None -> raise.raise @@ corner_case __LOC__ (* should be caught when typing the matchee *)
      )
    in
    let present = List.filter_map ~f:(fun (c,eq_opt) -> match eq_opt with Some eq -> Some (c,eq) | None -> None) grouped_eqs in
    let present_cases = List.map present ~f:aux_p in
    let missing = List.filter_map ~f:(fun (c,eq_opt) -> match eq_opt with Some _ -> None | None -> Some (c,body_t)) grouped_eqs in
    let missing_cases = List.map ~f:aux_m missing in
    let cases = O.Match_variant { cases = missing_cases @ present_cases ; tv = matchee_t } in
    O.make_e (O.E_matching { matchee ; cases }) body_t
  | [] -> raise.raise @@ corner_case __LOC__

and product_rule ~raise : err_loc:Location.t -> typed_pattern -> matchees -> equations -> rest -> O.expression =
  fun ~err_loc product_shape ms eqs def ->
  match ms with
  | mhd::_ -> (
    let lb :(_ * _ O.binder) list =
      let (p,t) = product_shape in
      match (p.wrap_content,t) with
      | P_tuple ps , t ->
        let aux : int -> _ O.pattern_repr Location.wrap -> (O.label * (O.type_expression O.binder)) =
          fun i proj_pattern ->
            let l = (O.Label (string_of_int i)) in
            let field_t = extract_record_type ~raise p l t in
            let var,attributes = match proj_pattern.wrap_content with
              | P_var x -> x.var,x.attributes
              | _ -> I.ValueVar.fresh ~loc:proj_pattern.location ~name:"tuple_proj" (),Stage_common.Helpers.empty_attribute
            in
            (l, {var;ascr=Some field_t;attributes})
        in
        List.mapi ~f:aux ps
      | P_record (labels,patterns) , t ->
        let aux : (O.label * _ O.pattern_repr Location.wrap)  -> (O.label * (O.type_expression O.binder)) =
          fun (l,proj_pattern) ->
            let var,attributes = match proj_pattern.wrap_content with
              | P_var x -> x.var,x.attributes
              | _ -> I.ValueVar.fresh ~loc:proj_pattern.location ~name:"record_proj" (),Stage_common.Helpers.empty_attribute
            in
            let field_t = extract_record_type ~raise p l t in
            (l , {var;ascr= Some field_t; attributes})
        in
        List.map ~f:aux (List.zip_exn labels patterns)
      | _ -> raise.raise @@ corner_case __LOC__
    in
    let aux : typed_pattern list * O.expression ->
              (typed_pattern list * O.expression) =
      fun (pl, body) ->
      match pl with
      | (prod,t)::ptl -> (
        let var_filler = (make_var_pattern (I.ValueVar.fresh ~name:"_" ()) , t) in
        match prod.wrap_content with
        | P_tuple ps ->
          let aux i p =
            let field_t = extract_record_type ~raise p (O.Label (string_of_int i)) t in
            (p,field_t)
          in
          let tps = List.mapi ~f:aux ps in
          (tps @ var_filler::ptl , body)
        | P_record (labels,ps) ->
          let aux label p =
            let field_t = extract_record_type ~raise p label t in
            (p,field_t)
          in
          let tps = List.map2_exn ~f:aux labels ps in
          (tps @ var_filler::ptl , body)
        | P_var _ ->
          let filler =
            let (p,t) = product_shape in
            match (p.wrap_content,t) with
            | P_tuple ps , t ->
              let aux i p =
                let field_t = extract_record_type ~raise p (O.Label (string_of_int i)) t in
                let v = match p.wrap_content with
                  | P_var _ -> p
                  | _ -> make_var_pattern (I.ValueVar.fresh ~loc:p.location ~name:"_" ())
                in
                (v,field_t)
              in
              List.mapi ~f:aux ps
            | P_record (labels,patterns) , t ->
              let aux l p =
                let field_t = extract_record_type ~raise p l t in
                let v = match p.wrap_content with
                  | P_var _ -> p
                  | _ -> make_var_pattern (I.ValueVar.fresh ~loc:p.location ~name:"_" ())
                in
                (v,field_t)
              in
              List.map2_exn ~f:aux labels patterns
            | _ -> raise.raise @@ corner_case __LOC__
          in
          (filler @ pl , body)
        | _ -> raise.raise @@ corner_case __LOC__
      )
      | [] -> raise.raise @@ corner_case __LOC__
    in
    let matchee_t = get_pattern_type ~raise eqs in
    let eqs' = List.map ~f:aux eqs in
    let fields = O.LMap.of_list lb in
    let new_matchees = List.map ~f:(fun (_,b) -> b.var) lb in
    let body = match_ ~raise ~err_loc (new_matchees @ ms) eqs' def in
    let cases = O.Match_record { fields; body ; tv = snd product_shape } in
    let matchee = O.e_a_variable mhd matchee_t in
    O.make_e (O.E_matching { matchee ; cases }) body.type_expression
  )
  | [] -> raise.raise @@ corner_case __LOC__

let compile_matching ~raise ~err_loc matchee (eqs: (O.type_expression O.pattern * O.type_expression * O.expression) list) =
  let eqs = List.map ~f:(fun (pattern,pattern_ty,body) -> ( [(pattern,pattern_ty)] , body )) eqs in
  let missing_case_default =
    let fs = O.make_e (O.E_literal (O.Literal_string Stage_common.Backends.fw_partial_match)) (O.t_string ()) in
    let t_fail =
      let a = O.TypeVar.of_input_var "a" in
      let b = O.TypeVar.of_input_var "b" in
      O.t_for_all a O.Type (O.t_for_all b O.Type (O.t_arrow (O.t_variable a ()) (O.t_variable b ()) ()))
    in
    let lamb = (O.e_variable (O.ValueVar.of_input_var "failwith") t_fail) in
    let args = fs in
    O.E_application {lamb ; args }
  in
  match_ ~raise ~err_loc [matchee] eqs missing_case_default
