(* ************************************************************************** *)
(*                                                                            *)
(*                        FoCaLiZe compiler                                   *)
(*                                                                            *)
(*            Raphaël Cauderlier                                              *)
(*                                                                            *)
(*               LIP6  --  INRIA Rocquencourt -- ENSTA ParisTech              *)
(*                                                                            *)
(*  Copyright 2007 - ... LIP6 and INRIA                                       *)
(*            2012 - ... ENSTA ParisTech                                      *)
(*  Distributed only by permission.                                           *)
(*                                                                            *)
(* ************************************************************************** *)

type let_binding_pre_computation = {
  lbpc_value_body : Env.DkGenInformation.value_body ;
  lbpc_params_with_type : (Parsetree.vname * Types.type_simple option) list ;
  lbpc_result_ty : Types.type_simple option ;
  lbpc_generalized_vars : Types.type_variable list
} ;;

type self_methods_status =
  | SMS_from_param of Parsetree.vname  (** Must be called "_p_Param_<meth>". *)
  | SMS_abstracted     (** Must be called "abst_<meth>". *)
  | SMS_from_record    (** Must be called "(hosting_species. if needed)
                           <rf_meth>". *)
;;

type recursive_methods_status =
  | RMS_abstracted     (** Must be called "abst_<meth>". *)
  | RMS_regular        (** Must be called directly by its name. *)
;;


(***** Constants *****)
(** For numbers, characters and strings literals, we use Sukerujo,
    a parser for Dedukti with some syntactic sugar. **)

let butfst (str : string) : string =
  String.sub str 1 (String.length str - 1)
;;

let generate_constant out cst =
  match cst.Parsetree.ast_desc with
   | Parsetree.C_int str ->
      let sign = (str.[0] = '-') in
      let abs_str =
        if str.[0] = '-' || str.[0] = '+'
        then butfst str
        else str
      in
      let print_abs fmter s = Format.fprintf fmter "%s" s in
      if sign
      then Format.fprintf out
                          "@[<2>(dk_int.opp@ ";
      Format.fprintf out
                     "@[<2>(dk_int.from_nat@ %a)@]"
                     print_abs abs_str;
      if sign then Format.fprintf out ")@]";
   | Parsetree.C_float _str ->
       (* [Unsure] *)
       Format.fprintf out "C_float"
   | Parsetree.C_bool str ->
       (* [true] maps on Dk "true". [false] maps on Dk "false". *)
       Format.fprintf out "dk_bool.%s" str
   | Parsetree.C_string str ->
      Format.fprintf out "\"%s\"" str;
   | Parsetree.C_char c ->
      Format.fprintf out "\'%c\'" c
;;

let print_ident out i =
  match i.Parsetree.ast_desc with
  | Parsetree.I_local vname
  | Parsetree.I_global (Parsetree.Vname vname) ->
     Parsetree_utils.pp_vname_with_operators_expanded out vname
  (* Hack for unit *)
  | Parsetree.I_global (Parsetree.Qualified ("basics", Parsetree.Vuident "()")) ->
     Format.fprintf out "dk_builtins.tt"
  (* nil and cons are keywords for Sukerujo *)
  | Parsetree.I_global (Parsetree.Qualified ("basics", Parsetree.Vuident "::")) ->
     Format.fprintf out "cons"
  | Parsetree.I_global (Parsetree.Qualified ("basics", Parsetree.Vuident "[]")) ->
     Format.fprintf out "nil"
  | Parsetree.I_global (Parsetree.Qualified (fname, vname)) ->
     Format.fprintf out "%s.%a"
       fname
       Parsetree_utils.pp_vname_with_operators_expanded vname
;;

let print_constr_ident out i =
  let Parsetree.CI id = i.Parsetree.ast_desc in
  print_ident out id
;;


(* Tuples are represented as nested couples and couples are a predefined
   datatype; we define here an ident for its constructor. *)
let pair_cident =
  let pair_ident_desc = Parsetree.I_global
                          (Parsetree.Qualified
                             ("dk_tuple",
                              Parsetree.Vlident "pair")) in
  let pair_ident = Parsetree_utils.make_ast pair_ident_desc in
  let pair_cident_desc = Parsetree.CI pair_ident in
  Parsetree_utils.make_ast pair_cident_desc
;;


(* Check that the constructor has a Dedukti mapping if it is external. *)
let check_constructor_ident ctx env cstr_expr =
  if cstr_expr = pair_cident then () else
    (begin
        let mapping_info =
          try
            Env.DkGenEnv.find_constructor
              ~loc: cstr_expr.Parsetree.ast_loc
              ~current_unit: ctx.Context.scc_current_unit cstr_expr env
          (* Since in Dk all the constructors must be inserted in the generation
       environment, if we don't find the constructor, then we were wrong
       somewhere else before. *)

          with _ -> assert false
        in
        (match mapping_info.Env.DkGenInformation.cmi_external_translation with
         | None -> ()
           (* The constructor isn't coming from an external definition. *)
         | Some external_expr -> (
           (* The constructor comes from an external definition. *)
           if not (List.exists
                   (function
                     | (Parsetree.EL_Dk, _) -> true
                     | (Parsetree.EL_Caml, _)
                     | (Parsetree.EL_Coq, _)
                     | ((Parsetree.EL_external _), _) -> false)
                   external_expr)
           then
               (* No Dk mapping found. *)
               raise
                 (Externals_generation_errs.No_external_constructor_def
                    ("Dk", cstr_expr))
        ))
      end)
;;

(* Exactly the same principle than for sum type constructors in the above
   function [check_constructor_ident]. *)
(* But also print the label. *)
let generate_record_label_for_method_generator ctx env label =
  try
    let mapping_info =
      Env.DkGenEnv.find_label
        ~loc: label.Parsetree.ast_loc
        ~current_unit: ctx.Context.scc_current_unit label env in
    (match mapping_info.Env.DkGenInformation.lmi_external_translation with
    | None -> (
        (* The label isn't coming from an external definition. *)
        let Parsetree.LI global_ident = label.Parsetree.ast_desc in
        match global_ident.Parsetree.ast_desc with
          | Parsetree.I_local name
          | Parsetree.I_global (Parsetree.Vname name) ->
              Format.fprintf ctx.Context.scc_out_fmter "%a"
                Parsetree_utils.pp_vname_with_operators_expanded name
          | Parsetree.I_global (Parsetree.Qualified (fname, name)) ->
              (* If the constructor belongs to the current compilation unit
                 then one must not qualify it. *)
              if fname <> ctx.Context.scc_current_unit then
                Format.fprintf ctx.Context.scc_out_fmter "%s.%a"
                  fname          (* No module name capitalization in Dk. *)
                  Parsetree_utils.pp_vname_with_operators_expanded name
              else
                Format.fprintf ctx.Context.scc_out_fmter "%a"
                  Parsetree_utils.pp_vname_with_operators_expanded name
        )
    | Some external_expr ->
        (* The constructor comes from an external definition. *)
        let (_, dk_binding) =
          try
            List.find
              (function
                | (Parsetree.EL_Dk, _) -> true
                | (Parsetree.EL_Caml, _)
                | (Parsetree.EL_Coq, _)
                | ((Parsetree.EL_external _), _) -> false)
              external_expr
          with Not_found ->
            (* No Dk mapping found. *)
            raise
              (Externals_generation_errs.No_external_field_def
                 ("Dk", label)) in
        (* Now directly generate the name the label is mapped onto. *)
        Format.fprintf ctx.Context.scc_out_fmter "%s" dk_binding)
  with _ ->
    (* Since in Dk all the record labels must be inserted in the generation
       environment, if we don't find the label, then we were wrong
       somewhere else before. *)
    assert false
;;


(* Takes an Parsetree.ast and print its type *)
let generate_simple_type_of_ast dkctx out_fmter a =
 match a.Parsetree.ast_type with
 | Parsetree.ANTI_none ->
    Format.fprintf out_fmter "no_type"
 | Parsetree.ANTI_irrelevant ->
    Format.fprintf out_fmter "irrelevant_type"
 | Parsetree.ANTI_scheme ts ->
    Dk_pprint.pp_type_simple_to_dk dkctx out_fmter (Types.specialize ts)
 | Parsetree.ANTI_type st ->
    Dk_pprint.pp_type_simple_to_dk dkctx out_fmter st
;;

(* ************************************************************************** *)
(* force_polymorphic_explicit_args: bool -> Context.species_compil_context -> *)
(*   Env.DkGenEnv.t -> Parsetree.pattern -> unit                             *)
(** {b Descr} : Emits dk code for a pattern. Attention, this function can
    also be used to generate code from a pettern but not in the context of
    generating a pattern in the target code (see description of
    [~force_polymorphic_explicit_args]).

    This function does more than its Coq counterpart because Dedukti patterns
    are only allowed in rewrite-rules, so at toplevel.
    Moreover, Dedukti patterns are not equivalent to ml patterns because
    confluence has to be guaranteed. Hence
      match x with
        | 0 -> 0
        | _ -> 1
    cannot be translated in Dedukti by two rewrite rules.
    TODO (future optimization): realize when patterns are orthogonal and can
    hence be compiled by rewrite-rules.

    In Dedukti, each pattern is translated as a function with a continuation.
    Exhaustivity is not checked, empty pattern-matching compiles to "run-time"
    failure.

    The code produced by this function is equivalent to
    (match e with pat -> d | _ -> k) : ret_type

    {b Args} :
      - [~d]: A function to print the term bound to the pattern.
      - [~k]: A continuation in case the pattern is not matched.
      - [~ret_type]: The type returned by the pattern.
      - [~e]: a function to print the expression matched

    {b Exported} : No                                                         *)
(* ************************************************************************** *)
let generate_pattern ctx dkctx env pattern
                     ~d ~k ~ret_type ~e =
  let out_fmter = ctx.Context.scc_out_fmter in
  let rec rec_gen_pat pat ~d ~k ~ret_type ~e =
    match pat.Parsetree.ast_desc with
    | Parsetree.P_const constant ->
       (* "match e with c -> d | _ -> k" is the same as "if e = c then d else k" *)
       Format.fprintf out_fmter "(dk_bool.ite (%a) "
                      (generate_simple_type_of_ast dkctx)
                      ret_type ;
       Format.fprintf out_fmter "(dk_builtins.eq (";
       generate_pattern_type pat;
       Format.fprintf out_fmter ") (";
       e ();
       Format.fprintf out_fmter ") (";
       generate_constant out_fmter constant;
       Format.fprintf out_fmter ")) (";
       d ();
       Format.fprintf out_fmter ") (";
       k ();
       Format.fprintf out_fmter "))"
     | Parsetree.P_var name ->
        (* "match e with x -> d | _ -> k" is the same as "(fun x -> d) e" *)
        Format.fprintf out_fmter "(%a :@ cc.eT@ "
                       Parsetree_utils.pp_vname_with_operators_expanded name;
        generate_pattern_type pat;
        Format.fprintf out_fmter " =>@ (";
        d ();
        Format.fprintf out_fmter "))@ ";
        e ()
     | Parsetree.P_as (p, name) ->
        (* "match e with p(y) as x -> d(x,y) | _ -> k"
           is the same as
           "(fun x -> (match e with p(y) -> d(x,y))) e" *)
        Format.fprintf out_fmter "(%a :@ "
                       Parsetree_utils.pp_vname_with_operators_expanded name;
        generate_pattern_type pat;
        Format.fprintf out_fmter " =>@ (";
        rec_gen_pat p ~d ~k ~ret_type ~e;
        Format.fprintf out_fmter "))@ ";
        e ()
     | Parsetree.P_wild ->
        (* "match e with _ -> d" is the same as "d" *)
        d ();
     | Parsetree.P_record _labs_pats ->
         Format.eprintf "generate_pattern P_record TODO@."
     | Parsetree.P_tuple [] -> assert false (* Tuples should not be empty *)
     | Parsetree.P_tuple [ p ] -> rec_gen_pat p ~d ~k ~ret_type ~e
     | Parsetree.P_tuple [ p1 ; p2 ] -> (* Tuples are a special case of constructor *)
        let desc = Parsetree.P_constr (pair_cident, [p1 ; p2] ) in
        (* Update pattern type to reflect current use *)
        let ast = Parsetree_utils.make_ast desc in
        ast.Parsetree.ast_type <- pat.Parsetree.ast_type;
        rec_gen_pat ast ~d ~k ~ret_type ~e
     | Parsetree.P_tuple (p :: pats) -> (* Tuples are a special case of constructor *)
        let tail = Parsetree_utils.make_ast (Parsetree.P_tuple pats) in
        let desc = Parsetree.P_constr (pair_cident, [p ; tail] ) in
        (* Update pattern type to reflect current use *)
        let ast = Parsetree_utils.make_ast desc in
        ast.Parsetree.ast_type <- pat.Parsetree.ast_type;
        rec_gen_pat ast ~d ~k ~ret_type ~e
     | Parsetree.P_paren p ->
         Format.fprintf out_fmter "(@[<1>" ;
         rec_gen_pat p ~d ~k ~ret_type ~e;
         Format.fprintf out_fmter ")@]"
     | Parsetree.P_constr (cident, pats) -> (* Most interesting case *)
        (* A function match__C : PV (Polymorphic variables) : * ->
                                 DT PV ->
                                 RT (Return type) : * ->
                                 then_case : (ty_1 -> .. ty_n-> RT) ->
                                 else_case : RT ->
                                 RT
                      is available in the same dedukti file than the constructor
         *)

        (* match e with P(p1, p2) -> d | _ -> k
           is the same as
           match e with
           | P(x, y) -> (match x with
              | p1 -> (match y with
                | p2 -> d
                | _ -> k)
              | _ -> k)
           | _ -> k
         where x and y are fresh variables (pattern_variable_%d)
         *)

        let Parsetree.CI ident = cident.Parsetree.ast_desc in
        let pattern_file_name, pattern_vname = match ident.Parsetree.ast_desc with
          | Parsetree.I_global (Parsetree.Qualified (f, v))  -> (f ^ ".", v)
          | Parsetree.I_global (Parsetree.Vname v)
          | Parsetree.I_local v -> ("", v)
        in
        let pattern_str =
          match Parsetree_utils.vname_as_string_with_operators_expanded pattern_vname with
          | "[]" -> "nil"
          | "::" -> "cons"
          | s -> s
        in
        Format.fprintf out_fmter "@[<1>%smatch__%s"
                       pattern_file_name
                       pattern_str;
        (* Now check that the constructor has a Dedukti mapping *)
        check_constructor_ident ctx env cident;
        (begin
            match pat.Parsetree.ast_type with
            | Parsetree.ANTI_type t ->
               Dk_pprint.pp_type_simple_args_to_dk dkctx out_fmter t
            | _ ->
               Format.fprintf out_fmter "(unknown_pattern_type %a)"
                              Parsetree_utils.pp_vname_with_operators_expanded
                              (Parsetree_utils.unqualified_vname_of_constructor_ident
                                 cident)
          end) ;
        (* Now the return type *)
        Format.fprintf out_fmter "@ ";
        generate_simple_type_of_ast dkctx out_fmter ret_type ;
        (* Now the matched term *)
        Format.fprintf out_fmter "@ ";
        e ();
        (* Now the pattern function (then case) *)
        Format.fprintf out_fmter "@ (";
        (* Then case 1/2: Abstract over fresh variables *)
        let count = ref 0 in
        List.iter (fun pat ->
                   Format.fprintf out_fmter "pattern_var_%d_ :@ cc.eT@ " !count;
                   generate_simple_type_of_ast dkctx out_fmter pat;
                   Format.fprintf out_fmter " =>@ (";
                   incr count)
                  pats;
        (* Then case 2/2: Generate the matching on the fresh variables *)
        rec_generate_pats_list 0 ~k ~d ~ret_type pats;
        (* Close parens *)
        for _ = 1 to !count do Format.fprintf out_fmter ")" done;
        Format.fprintf out_fmter ")";

        (* Now the continuation (else case) *)
        Format.fprintf out_fmter "@ (";
        k ();
        Format.fprintf out_fmter ")";
        Format.fprintf out_fmter "@]";


  and rec_generate_pats_list count ~k ~d ~ret_type = function
    | [] -> d ()
    | pat :: pats ->
       (* we produce the term
          match pattern_var_%{count}_ with
            | pat -> recursive_call
            | _ -> k
        *)
       let fresh_var_name =
         Parsetree.Vlident (Printf.sprintf "pattern_var_%d_" count)
       in
       (* let fresh_var_pat = Parsetree.P_var fresh_var_name in *)
       (* let fresh_var_desc = Parsetree.EI_local fresh_var_name in *)
       (* let fresh_var = Parsetree_utils.make_ast fresh_var_desc in *)
       rec_gen_pat
         pat
         ~d: (fun () ->
                    rec_generate_pats_list (count+1) ~k ~d ~ret_type pats)
         ~k
         ~ret_type
         ~e: (fun () -> Sourcify.pp_vname out_fmter fresh_var_name)

  and generate_pattern_type (p : Parsetree.pattern) =
    generate_simple_type_of_ast dkctx out_fmter p
  in

  (* ********************** *)
  (* Now, let's do the job. *)
  rec_gen_pat pattern ~d ~k ~ret_type ~e
;;


(* [local_idents] : the bound variables, used to distinguish in-parameter. *)

let generate_expr_ident_for_E_var ctx ~in_recursive_let_section_of ~local_idents
    ~self_methods_status ~recursive_methods_status ident =
  let out_fmter = ctx.Context.scc_out_fmter in
  let (_, species_name) = ctx.Context.scc_current_species in
  match ident.Parsetree.ast_desc with
   | Parsetree.EI_local vname -> (
       (* Thanks to the scoping pass, identifiers remaining "local" are either
          really let-bound in the context of the expression, hence have a
          direct mapping between FoCaL and OCaml code, or species
          "IN"-parameters and then must be mapped onto the lambda-lifted
          parameter introduced for it in the context of the current species.
          Be careful, because a recursive method called in its body is scoped
          AS LOCAL ! And because recursive methods do not have dependencies
          together, there is no way to recover the extra parameters to apply to
          them in this configuration. Hence, to avoid forgetting these extra
          arguments, we must use here the information recorded in the context,
          i.e. the extra arguments of the recursive functions.
          To check if a "smelling local" identifier is really local or a
          "IN"-parameter of the species, we use the same reasoning that in
          [param_dep_analysis.ml]. Check justification over there ! *)
       if (List.exists
             (fun species_param ->
               match species_param with
                | Env.TypeInformation.SPAR_in (vn, _, _) -> vn = vname
                | Env.TypeInformation.SPAR_is ((_, vn), _, _, _, _) ->
                    (Parsetree.Vuident vn) = vname)
             ctx.Context.scc_species_parameters_names) &&
         (not (List.mem vname local_idents)) then (
         (* In fact, a species "IN"-parameter. This parameter was of the form
            "foo in C". Then it's naming scheme will be "_p_" + the species
            parameter's name + the method's name that is trivially the
            parameter's name again (because this last one is computed as the
            "stuff" a dependency was found on, and in the case of a
            "IN"-parameter, the dependency can only be on the parameter's value
            itself, not on any method since there is none !). *)
         Format.fprintf out_fmter "_p_%a_%a"
           Parsetree_utils.pp_vname_with_operators_expanded vname
           Parsetree_utils.pp_vname_with_operators_expanded vname
         )
       else (
         (* Really a local identifier or a call to a recursive method. *)
         let is_a_rec_fun = List.mem vname in_recursive_let_section_of in
         (* If the function is recursive, we must apply to it the naming scheme
            applied to recursive functions of Self. This means if
            must be called "abst_xxx" or "xxx" depending on the current
            "recursive_methods_status". In effect, when giving to Zenon the
            body of a recursive function, since we are in a Section, the
            methods of "Self" are abstracted and named "abst_xxx". In all
            other places, the recursive functions names must be generated
            without anything more than their name. *)
         if is_a_rec_fun then
           (match recursive_methods_status with
             | RMS_abstracted ->
                 Format.fprintf out_fmter "abst_%a"
                   Parsetree_utils.pp_vname_with_operators_expanded vname
             | RMS_regular ->
                 Format.fprintf out_fmter "%a"
                   Parsetree_utils.pp_vname_with_operators_expanded vname)
         else
           Format.fprintf out_fmter "%a"
             Parsetree_utils.pp_vname_with_operators_expanded vname ;
         (* Because this method can be recursive, we must apply it to its
            extra parameters if it has some ONLY if the function IS NOT a
            recursive one. In effect, in this last case, a Section has been
            created with all the abstrations the function requires. So no need
            to apply each recursive call. *)
         if not is_a_rec_fun then (
            try
            (* We are not in a recursive definition, so we can apply to the
               lambda-lifted extra arguments. *)
            let extra_args =
               List.assoc vname ctx.Context.scc_lambda_lift_params_mapping in
             List.iter (fun s -> Format.fprintf out_fmter "@ %s" s) extra_args
              with Not_found -> ()
            )
         )
      )
   | Parsetree.EI_global (Parsetree.Vname _) ->
       (* In this case, may be there is some scoping process missing. *)
       assert false
   | Parsetree.EI_global (Parsetree.Qualified (mod_name, vname)) ->
       (* Call the Dk corresponding identifier in the corresponding   *)
       (* module (i.e. the [mod_name]). If the module is the currently *)
       (* compiled one, then do not qualify the identifier.            *)
       if mod_name <> ctx.Context.scc_current_unit then
         Format.fprintf out_fmter "%s.%a"
           mod_name Parsetree_utils.pp_vname_with_operators_expanded vname
       else
         Format.fprintf out_fmter "%a"
           Parsetree_utils.pp_vname_with_operators_expanded vname
   | Parsetree.EI_method (coll_specifier_opt, vname) -> (
       match coll_specifier_opt with
       | None
       | Some (Parsetree.Vname (Parsetree.Vuident "Self")) -> (
           (* Method call from the current species. *)
           match self_methods_status with
           | SMS_abstracted ->
              (* On the Dedukti side, def dependencies are not
                 abstracted because Dedukti lacks let. *)
              (* We check here if the method is defined,
                 in which case we print its full name and dependencies *)
              let is_defined = false in
              if is_defined
              then
                Format.fprintf out_fmter "%a__%a"
                  Sourcify.pp_vname (snd ctx.Context.scc_current_species)
                  Parsetree_utils.pp_vname_with_operators_expanded vname
              else
                Format.fprintf out_fmter "abst_%a"
                  Parsetree_utils.pp_vname_with_operators_expanded vname
           | SMS_from_record ->
               Format.fprintf out_fmter "%a__rf_%a"
                 Sourcify.pp_vname species_name
                 Parsetree_utils.pp_vname_with_operators_expanded vname
           | SMS_from_param spe_param_name ->
               Format.fprintf out_fmter "_p_%a_%a"
                 Parsetree_utils.pp_vname_with_operators_expanded
                 spe_param_name
                 Parsetree_utils.pp_vname_with_operators_expanded vname
          )
       | Some coll_specifier -> (
           match coll_specifier with
           | Parsetree.Vname coll_name -> (
               (* Method call from a species that is not the current but is
                  implicitely in the current compilation unit. May be
                  either a paramater or a toplevel defined collection. *)
               if List.exists
                   (fun species_param ->
                     match species_param with
                     | Env.TypeInformation.SPAR_in (vn, _, _) ->
                         vn = coll_name
                     | Env.TypeInformation.SPAR_is ((_, vn), _, _, _, _) ->
                         (Parsetree.Vuident vn) = coll_name)
                   ctx.Context.scc_species_parameters_names then (
                 (* It comes from a parameter. To retrieve the related
                    method name we build it the same way we built it
                    while generating the extra Dk function's parameters due
                    to depdencencies coming from the species parameter.
                    I.e: "_p_", followed by the species parameter name,
                    followed by "_", followed by the method's name. *)
                 let prefix =
                   "_p_" ^ (Parsetree_utils.name_of_vname coll_name) ^ "_" in
                 Format.fprintf out_fmter "%s%a"
                   prefix Parsetree_utils.pp_vname_with_operators_expanded
                   vname
                )
               else (
                 if coll_name = (snd ctx.Context.scc_current_species) then (
                   (* In fact, the name is qualified but with ourself
                      implicitely in the current compilation unit. Then, we
                      are not in the case of a toplevel species but in the
                      case where a substitution replaced Self by ourself.
                      We then must refer to our local record field. *)
                   Format.fprintf out_fmter "%a__rf_%a"
                     Sourcify.pp_vname species_name
                     Parsetree_utils.pp_vname_with_operators_expanded vname
                  )
                 else (
                   (* It comes from a toplevel stuff, hence not abstracted by
                      lambda-lifting. Then, we get the field of the
                      module representing the collection. *)
                   Format.fprintf out_fmter "%a__%a"
                     Parsetree_utils.pp_vname_with_operators_expanded coll_name
                     Parsetree_utils.pp_vname_with_operators_expanded vname
                  )
                )
              )
           | Parsetree.Qualified (module_name, coll_name) -> (
               if module_name = ctx.Context.scc_current_unit then (
                 (* Exactly like when it is method call from a species that
                    is not the current but is implicitely in the current
                    compilation unit : the call is performed to a method a
                    species that is EXPLICITELY in the current compilation
                    unit. *)
                 if List.exists
                     (fun species_param ->
                       match species_param with
                       | Env.TypeInformation.SPAR_in (vn, _, _) ->
                           vn = coll_name
                       | Env.TypeInformation.SPAR_is ((_, vn), _, _, _, _) ->
                           (Parsetree.Vuident vn) = coll_name)
                     ctx.Context.scc_species_parameters_names then (
                   (* It comes from one of our species parameters. *)
                   let prefix =
                     "_p_" ^ (Parsetree_utils.name_of_vname coll_name) ^"_" in
                   Format.fprintf out_fmter "%s%a"
                     prefix Parsetree_utils.pp_vname_with_operators_expanded
                     vname
                  )
                 else (
                   (* It's not from one of our species parameter but it comes
                      from the current compilation unit. Let's check if the
                      species is ourself. In this case, liek above we must
                      refer to our local record field. *)
                   if coll_name = (snd ctx.Context.scc_current_species) then
                     Format.fprintf out_fmter "%a__rf_%a"
                       Sourcify.pp_vname species_name
                       Parsetree_utils.pp_vname_with_operators_expanded vname
                   else (
                     Format.fprintf out_fmter "%a__%a"
                       Parsetree_utils.pp_vname_with_operators_expanded
                       coll_name
                       Parsetree_utils.pp_vname_with_operators_expanded vname
                    )
                  )
                )
               else (
                 (* The called method belongs to a species that is not
                    ourselves and moreover belongs to another compilation
                    unit. May be a species from the toplevel of another
                    FoCaL source file. *)
                 Format.fprintf out_fmter "%s.%a__%a"
                   module_name
                   Parsetree_utils.pp_vname_with_operators_expanded coll_name
                   Parsetree_utils.pp_vname_with_operators_expanded vname
                )
              )
          )
      )
;;


(* Generate an expr_ident with methods abstracted, usefull for
   declaring it to Zenon. *)
let generate_expr_ident ctx ident =
  generate_expr_ident_for_E_var
    ctx
    ~in_recursive_let_section_of:[]
    ~local_idents:[]
    ~self_methods_status:SMS_abstracted
    ~recursive_methods_status:RMS_abstracted
    ident
;;

(* Generate the type scheme associated with an ident in the environment. *)
let generate_expr_ident_type ctx print_ctx env ident =
  let out_fmter = ctx.Context.scc_out_fmter in
  let id_type_simple =
    (match ident.Parsetree.ast_type with
     | Parsetree.ANTI_none | Parsetree.ANTI_irrelevant
     | Parsetree.ANTI_scheme _ -> assert false
     | Parsetree.ANTI_type t -> t) in
  let id_type_scheme =
    try
      let vb =
        (Env.DkGenEnv.find_value
           ~loc: ident.Parsetree.ast_loc
           ~current_unit: ctx.Context.scc_current_unit
           ~current_species_name: (Some (Parsetree_utils.name_of_vname
                                           (snd ctx.Context.scc_current_species)))
           ident env)
      in
      (match vb with
       | Env.DkGenInformation.VB_toplevel_let_bound (_, _, ts, _) -> Some ts
       | Env.DkGenInformation.VB_non_toplevel
       | Env.DkGenInformation.VB_toplevel_property _ -> None)
    with
      (* If the identifier was not found, then it was may be a local
                identifier bound by a pattern. Then we can safely ignore it. *)
      Env.Unbound_identifier (_, _) -> None
  in
  match id_type_scheme with
  | None -> Dk_pprint.pp_type_simple_to_dk_with_eps print_ctx out_fmter id_type_simple
  | Some sch ->
     Dk_pprint.pp_type_scheme_to_dk print_ctx out_fmter sch
;;





(* ************************************************************************** *)
(** {b Descr}: Initiate computation of things needed by [let_binding_compile]
    and also needed to pre-enter recursive identifiers in the Dk env in order
    to know their number of extra arguments due to polymorphism. In effect, in
    case of recursivity (and moreover mutual recursivity), this info is needed
    in order to apply recursive identifiers in recursive call to the right
    number of arguments.
    Since the determination of this number of extra arguments involves
    computation of other things useful for effective code generation, we
    factorize these computation here and make these results available to
    [let_binding_compile] to avoid computing them again.
    It directly returns an environment in which the identifier is bound to the
    correct information. In effect, code generation (occuring after the
    present function is called) doesn't modify this information.              *)
(* ************************************************************************** *)
let pre_compute_let_binding_info_for_rec env bd ~rec_status ~toplevel =
  (* Generate the parameters if some, with their type constraints. *)
  let params_names = List.map fst bd.Parsetree.ast_desc.Parsetree.b_params in
  (* Recover the type scheme of the bound ident. *)
  let def_scheme =
    (match bd.Parsetree.ast_type with
     | Parsetree.ANTI_none | Parsetree.ANTI_irrelevant
     | Parsetree.ANTI_type _ -> assert false
     | Parsetree.ANTI_scheme s -> s) in
  (* We do not have anymore information about "Self"'s structure... *)
  let (params_with_type, result_ty, generalized_vars) =
    MiscHelpers.bind_parameters_to_types_from_type_scheme
      ~self_manifest: None (Some def_scheme) params_names in
  let value_body =
    if not toplevel then Env.DkGenInformation.VB_non_toplevel
    else
      Env.DkGenInformation.VB_toplevel_let_bound
        (rec_status, params_names, def_scheme,
         bd.Parsetree.ast_desc.Parsetree.b_body) in
  let env' =
    (match rec_status with
    | Env.RC_rec _ ->
        let toplevel_loc =
          if toplevel then Some bd.Parsetree.ast_loc else None in
        Env.DkGenEnv.add_value
          ~toplevel: toplevel_loc bd.Parsetree.ast_desc.Parsetree.b_name
          value_body env
    | Env.RC_non_rec -> env) in
  (env',
   { lbpc_value_body = value_body ;
     lbpc_params_with_type = params_with_type ;
     lbpc_result_ty = result_ty ;
     lbpc_generalized_vars = generalized_vars })
;;



(* ************************************************************************** *)
(** {b Descr}: Simply folds the pre-computation of one binding on a list of
    bindings (not forcely mutually recursive), accumulating the obtained
    environment at each step.                                                 *)
(* ************************************************************************** *)
let pre_compute_let_bindings_infos_for_rec ~rec_status ~toplevel env bindings =
  (* And not [List.fold_right otherwise the bindings will be processed in
     reverse order. However, the list of infos needs be reversed to
     keep them in the same order than the list of bindings (was bug #60). *)
  let (new_env, reved_infos) =
    List.fold_left
      (fun (env_accu, infos_accu) binding ->
        let (env', info) =
          pre_compute_let_binding_info_for_rec
            ~rec_status ~toplevel env_accu binding in
        (env', info :: infos_accu))
      (env, [])
      bindings in
  (new_env, (List.rev reved_infos))
;;

let generate_expr ctx ~in_recursive_let_section_of ~local_idents
    ~self_methods_status ~recursive_methods_status initial_env
    initial_expression =
  let out_fmter = ctx.Context.scc_out_fmter in
  (* Create the dk type print context. *)
  let print_ctx = {
    Dk_pprint.dpc_current_unit = ctx.Context.scc_current_unit ;
    Dk_pprint.dpc_current_species =
      Some
        (Parsetree_utils.type_coll_from_qualified_species
           ctx.Context.scc_current_species) ;
    Dk_pprint.dpc_collections_carrier_mapping =
      ctx.Context.scc_collections_carrier_mapping } in

  let rec rec_generate_expr loc_idents env expression =
    (* Now, dissecate the expression core. *)
    match expression.Parsetree.ast_desc with
     | Parsetree.E_self ->
         (* "Self" is not a first-class value ! *)
         assert false
     | Parsetree.E_const cst -> generate_constant out_fmter cst
     | Parsetree.E_fun (vnames, body) ->
         (* Get the type of the function. *)
         let fun_ty =
           (match expression.Parsetree.ast_type with
            | Parsetree.ANTI_none | Parsetree.ANTI_irrelevant
            | Parsetree.ANTI_scheme _ -> assert false
            | Parsetree.ANTI_type t -> t) in
         Format.fprintf out_fmter "@[<2>(" ;
         (* Now, print each parameter with it's type until we arrive to the
            return type of the function. DO NOT fold_right ! *)
         ignore
           (List.fold_left
              (fun accu_ty arg_name ->
                (* We do not have anymore information about "Self"'s
                   structure... *)
                let arg_ty =
                  Types.extract_fun_ty_arg ~self_manifest: None accu_ty in
                let res_ty =
                  Types.extract_fun_ty_result ~self_manifest: None accu_ty in
                Format.fprintf out_fmter "%a :@ %a =>@ "
                  Parsetree_utils.pp_vname_with_operators_expanded arg_name
                  (Dk_pprint.pp_type_simple_to_dk_with_eps print_ctx) arg_ty ;
                (* Return the remainder of the type to continue. *)
                res_ty)
              fun_ty
              vnames) ;
         Format.fprintf out_fmter "(" ;
         rec_generate_expr (vnames @ loc_idents) env body ;
         Format.fprintf out_fmter "))@]" ;
     | Parsetree.E_var ident -> (
       let current_species_name =
         Some
           (Parsetree_utils.name_of_vname
              (snd ctx.Context.scc_current_species)) in
       let id_type_simple : Types.type_simple =
         (match expression.Parsetree.ast_type with
          | Parsetree.ANTI_none | Parsetree.ANTI_irrelevant
          | Parsetree.ANTI_scheme _ -> assert false
          | Parsetree.ANTI_type t -> t) in
       let id_type_scheme =
         try
           let vb =
             (Env.DkGenEnv.find_value
                ~loc: ident.Parsetree.ast_loc
                ~current_unit: ctx.Context.scc_current_unit
                ~current_species_name ident env) in
           (match vb with
             | Env.DkGenInformation.VB_toplevel_let_bound (_, _, ts, _) -> Some ts
             | Env.DkGenInformation.VB_non_toplevel
             | Env.DkGenInformation.VB_toplevel_property _ -> None)
         with
           (* If the identifier was not found, then it was may be a local
                identifier bound by a pattern. Then we can safely ignore it. *)
           Env.Unbound_identifier (_, _) -> None
       in
       let nb_polymorphic_args =
         match id_type_scheme with
         | Some ts ->
            let (l, _) = Types.scheme_split ts in List.length l
         | None -> 0
       in

       (* If some extra "_" are needed, then enclose the whole expression
            between parens (was bug #50). *)
         if nb_polymorphic_args > 0 then Format.fprintf out_fmter "@[<2>(" ;
         generate_expr_ident_for_E_var
           ctx ~in_recursive_let_section_of ~local_idents: loc_idents
           ~self_methods_status ~recursive_methods_status ident ;
         (* Now, add the extra type parameters if the identifier is polymorphic. *)
         if nb_polymorphic_args > 0 then (
           let type_scheme =
             match id_type_scheme with Some ts -> ts | None -> assert false
           in
           let type_arguments =
             Types.unify_with_instance
               type_scheme
               id_type_simple
           in
           assert (List.length type_arguments = nb_polymorphic_args);
           List.iter (fun st ->
                      Format.fprintf out_fmter "@ (%a)"
                                     (Dk_pprint.pp_type_simple_to_dk print_ctx) st
                     )
                     type_arguments;
           (* Close the opened parenthesis if one was opened. *)
           if nb_polymorphic_args > 0 then Format.fprintf out_fmter ")@]"
         )
     )
     | Parsetree.E_app (func_expr, args) ->
         Format.fprintf out_fmter "@[<2>(" ;
         rec_generate_expr loc_idents env func_expr ;
         Format.fprintf out_fmter "@ " ;
         rec_generate_exprs_list ~comma: false loc_idents env args ;
         Format.fprintf out_fmter ")@]"
     | Parsetree.E_constr (cstr_ident, args) ->
         Format.fprintf out_fmter "@[<1>(%a"
           print_constr_ident cstr_ident;
         check_constructor_ident ctx env cstr_ident;
         (* Add the type arguments of the constructor. *)
         begin match expression.Parsetree.ast_type with
         | Parsetree.ANTI_type t ->
             Dk_pprint.pp_type_simple_args_to_dk print_ctx out_fmter t
         | _ -> assert false
         end;
         begin match args with
          | [] -> ()
          | _ ->
              Format.fprintf out_fmter "@ " ;
              rec_generate_exprs_list ~comma: false loc_idents env args ;
         end;
         Format.fprintf out_fmter ")@]" ;
     | Parsetree.E_match (expr, pats_exprs) ->
        let rec generate_pattern_matching = function
          | [] ->
             Format.fprintf out_fmter "(dk_fail.fail@ ";
             generate_simple_type_of_ast print_ctx out_fmter expression;
             Format.fprintf out_fmter ")"
          | (pat, d) :: pats ->
             generate_pattern ctx print_ctx env pat
                              ~d: (fun () -> rec_generate_expr loc_idents env d)
                              ~ret_type: d
                              ~k: (fun () -> generate_pattern_matching pats)
                              ~e: (fun () -> rec_generate_expr loc_idents env expr)
        in
        generate_pattern_matching pats_exprs;
     (*  *)
     | Parsetree.E_if (expr1, expr2, expr3) ->
         Format.fprintf out_fmter "@[<2>(dk_bool.ite@ " ;
         generate_simple_type_of_ast print_ctx out_fmter expr2;
         Format.fprintf out_fmter "@ " ;
         rec_generate_expr loc_idents env expr1 ;
         Format.fprintf out_fmter "@ " ;
         rec_generate_expr loc_idents env expr2 ;
         Format.fprintf out_fmter "@ " ;
         rec_generate_expr loc_idents env expr3 ;
         Format.fprintf out_fmter ")@]"
     | Parsetree.E_let (let_def, in_expr) ->
        let (env, pre_comp_infos) =
          pre_compute_let_bindings_infos_for_rec
            ~rec_status: Env.RC_non_rec
            ~toplevel: false env
            let_def.Parsetree.ast_desc.Parsetree.ld_bindings in
        let rec aux out_fmter = function
         | ([], []) -> rec_generate_expr loc_idents env in_expr
         | (fst_bnd :: next_bnds,
            fst_pre_comp_info :: next_pre_comp_info) ->
            (* Simply translate by a beta redex,
               this only works for non-recursive local lets *)
            Format.fprintf out_fmter "@[<2>((%a : %a =>@ %a)@ %a)@]"
              Parsetree_utils.pp_vname_with_operators_expanded
              fst_bnd.Parsetree.ast_desc.Parsetree.b_name
              (Dk_pprint.pp_type_simple_to_dk_with_eps print_ctx)
              (match fst_pre_comp_info.lbpc_result_ty with
               | None -> assert false
               | Some t -> t)
              aux (next_bnds, next_pre_comp_info)
              (fun _ -> rec_generate_expr loc_idents env)
              (match fst_bnd.Parsetree.ast_desc.Parsetree.b_body with
               | Parsetree.BB_logical _ -> assert false
               | Parsetree.BB_computational e -> e)
         | _ -> assert false
        in
        aux
          out_fmter
          (let_def.Parsetree.ast_desc.Parsetree.ld_bindings,
           pre_comp_infos)
     | Parsetree.E_record labs_exprs ->
         (* Use the Dk syntax {| .. := .. ; .. := .. |}. *)
         Format.fprintf out_fmter "@[<1>{|@ " ;
         rec_generate_record_field_exprs_list env loc_idents labs_exprs ;
         Format.fprintf out_fmter "@ |}@]"
     | Parsetree.E_record_access (expr, label) -> (
         rec_generate_expr loc_idents env expr ;
         Format.fprintf out_fmter ".@[<2>(" ;
         generate_record_label_for_method_generator ctx env label;
         (* Add the type arguments of the ***record type***, not the full
            expression type. *)
         (match expr.Parsetree.ast_type with
         | Parsetree.ANTI_type t ->
             Dk_pprint.pp_type_simple_args_to_dk print_ctx out_fmter t
         | _ -> assert false) ;
         Format.fprintf out_fmter ")@]"
        )
     | Parsetree.E_record_with (_expr, _labels_exprs) ->
         Format.fprintf out_fmter "E_record_with"
     | Parsetree.E_tuple exprs -> (
         match exprs with
          | [] -> assert false
          | [one] -> rec_generate_expr loc_idents env one
          | _ ->
              Format.fprintf out_fmter "@[<1>(" ;
              rec_generate_exprs_list ~comma: true loc_idents env exprs ;
              Format.fprintf out_fmter ")@]"
        )
     | Parsetree.E_sequence exprs ->
         let rec loop ppf = function
          | [] -> ()
          | [one] -> rec_generate_expr loc_idents env one
          | _ :: exprs -> loop ppf exprs in
         Format.fprintf out_fmter "@[<1>(%a)@]" loop exprs
     | Parsetree.E_external external_expr ->
         (begin
         let e_translation =
           external_expr.Parsetree.ast_desc.Parsetree.ee_external in
         try
           (* Simply a somewhat verbatim output of the Dk translation. *)
           let (_, dk_code) =
             List.find
               (function
                 | (Parsetree.EL_Dk, _) -> true
                 | (Parsetree.EL_Caml, _)
                 | (Parsetree.EL_Coq, _)
                 | ((Parsetree.EL_external _), _) -> false)
               e_translation.Parsetree.ast_desc in
           Format.fprintf out_fmter "%s" dk_code
         with Not_found ->
           (* No Dk mapping found. *)
           raise
             (Externals_generation_errs.No_external_value_def
                ("Dk", (Parsetree.Vlident "<expr>"),
                 expression.Parsetree.ast_loc))
         end)
     | Parsetree.E_paren expr ->
         Format.fprintf out_fmter "@[<1>(" ;
         rec_generate_expr loc_idents env expr ;
         Format.fprintf out_fmter ")@]"



  (* [Same] Quasi same code than for OCaml. *)
  and rec_generate_record_field_exprs_list env loc_idents = function
    | [] -> ()
    | [(label, last)] ->
        (* In record expression, no need to print extra _ even if the record
           type is polymorphic. *)
        ignore (generate_record_label_for_method_generator ctx env label) ;
        Format.fprintf out_fmter " :=@ " ;
        rec_generate_expr loc_idents env last
    | (h_label, h_expr) :: q ->
        ignore (generate_record_label_for_method_generator ctx env h_label) ;
        Format.fprintf out_fmter " :=@ " ;
        rec_generate_expr loc_idents env h_expr ;
        Format.fprintf out_fmter ";@ " ;
        rec_generate_record_field_exprs_list env loc_idents q


  and generate_expression_type (e : Parsetree.expr) =
    match e.Parsetree.ast_type with
    | Parsetree.ANTI_none
    | Parsetree.ANTI_irrelevant
    | Parsetree.ANTI_scheme _ ->
       assert false     (* An expression should have a meaningful type *)
    | Parsetree.ANTI_type st ->
       Dk_pprint.pp_type_simple_to_dk print_ctx out_fmter st

  and rec_generate_exprs_type_list ~comma loc_idents env = function
    | [] -> ()
    | [last] -> generate_expression_type last
    | h :: q ->
       if comma then Format.fprintf out_fmter "dk_tuple.prod@ (";
       generate_expression_type h;
       Format.fprintf out_fmter ")@ (";
       rec_generate_exprs_type_list ~comma loc_idents env q;
       Format.fprintf out_fmter ")"

  and rec_generate_exprs_list ~comma loc_idents env = function
    | [] -> ()
    | [last] -> rec_generate_expr loc_idents env last
    | h :: q ->
       if comma then            (* There is no builtin syntax for pairs in Dedukti, we use a pair function instead. *)
         (Format.fprintf out_fmter "(dk_tuple.pair@ (";
          generate_expression_type h;
          Format.fprintf out_fmter ")@ (";
          rec_generate_exprs_type_list ~comma loc_idents env q;
          Format.fprintf out_fmter ")@ ";
         );
        Format.fprintf out_fmter "(";
        rec_generate_expr loc_idents env h ;
        Format.fprintf out_fmter ")@ " ;
        rec_generate_exprs_list ~comma loc_idents env q;
        if comma then Format.fprintf out_fmter ")"
  in


  (* ************************************************ *)
  (* Now, let's really do the job of [generate_expr]. *)
  rec_generate_expr local_idents initial_env initial_expression
;;
