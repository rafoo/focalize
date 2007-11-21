(***********************************************************************)
(*                                                                     *)
(*                        FoCaL compiler                               *)
(*            Fran�ois Pessaux                                         *)
(*            Pierre Weis                                              *)
(*            Damien Doligez                                           *)
(*                               LIP6  --  INRIA Rocquencourt          *)
(*                                                                     *)
(*  Copyright 2007 LIP6 and INRIA                                      *)
(*  Distributed only by permission.                                    *)
(*                                                                     *)
(***********************************************************************)

(* $Id: infer.ml,v 1.89 2007-11-21 16:34:15 pessaux Exp $ *)


(* *********************************************************************** *)
(** {b Descr} : Exception used to inform that a sum type constructor was
               used with an incorrect arity. The correct expected arity is
              stored in the second argument of the exception constructor.

    {b Rem} : Exported outside this module.                                *)
(* *********************************************************************** *)
exception Bad_sum_type_constructor_arity of
  (Parsetree.constructor_ident *     (** The name of the misused sum type
         constructor. *)
   Env.TypeInformation.constructor_arity (** The correct arity it should have
             be used. *)
  )
;;



(* ************************************************************************ *)
(** {b Descr} : Exception raised when a type variable was not found inside
              the [tyvars_mapping] of current [typing_context]. This means
              that while typechecking a type definition, its body contains
              a type variable not specified in the type parameters list.

    {b Rem} : Exported outside this module.                                 *)
(* ************************************************************************ *)
exception Unbound_type_variable of
  (Location.t *        (* The location where the variable was found unbound. *)
   Parsetree.vname)    (** The name of the unbound variable. *)
;;



(* ************************************************************************* *)
(** {b Descr} : Exception raised when a method is defined several times in
              the same species.

    {b Rem} : Exported outside this module.                                  *)
(* ************************************************************************* *)
exception Method_multiply_defined of
  (Parsetree.vname *                (** The method's name. *)
   Parsetree.qualified_species)    (** The species's name and module
       where the method is defined. *)
;;



(* ********************************************************************** *)
(** {b Descr} : Exception raised when a type constructor is applied to an
              incorrect number of type arguments.

    {b Rem} : Exported outside this module.                               *)
(* ********************************************************************** *)
exception Bad_type_arity of
  (Parsetree.ident *   (** The name of the misused type constructor. *)
   int *               (** The expected arity. *)
   int)                (** The arity the constructor was used with. *)
;;



(* ********************************************************************* *)
(** {b Descr} : Exception raised when "rep" is defined several times in
              the same species or when it is defined several time during
              the inheritance.

    {b Rem} : Exported outside this module.                              *)
(* ********************************************************************* *)
exception Rep_multiply_defined of Location.t;;



(* ******************************************************************* *)
(** {b Descr} : During subspecies relation checking, a field was found
              with 2 incompatible types.

    {b Rem} : Exported outside this module.                            *)
(* ******************************************************************* *)
exception Not_subspecies_conflicting_field of
  ((** The collection name that should be a subspecies of the one below. *)
   Types.type_collection *
   (** The collection name that should be an overspecies of the one above. *)
   Types.type_collection *
   Parsetree.vname *     (** Name of the field. *)
   Types.type_simple *   (** First subpart of type found for this field. *)
   Types.type_simple *   (** Second subpart of type found for this field. *)
   Location.t)           (** Related location when the error occured. *)
;;



(* ******************************************************************* *)
(** {b Descr} : During subspecies relation checking, a field was found
              with 2 types that can't be unified because one of them
              occurs in the other.

    {b Rem} : Exported outside this module.
              Note that I can't really see how this coudl happen...    *)
(* ******************************************************************* *)
exception Not_subspecies_circular_field of
  ((** The collection name that should be a subspecies of the one below. *)
   Types.type_collection *
   (** The collection name that should be an overspecies of the one above. *)
   Types.type_collection *
   Parsetree.vname *     (** Name of the field. *)
   Types.type_simple *   (** First subpart of type found for this field. *)
   Types.type_simple *   (** Second subpart of type found for this field. *)
   Location.t)           (** Related location when the error occured. *)
;;



(* ******************************************************************* *)
(** {b Descr} : During subspecies relation checking, a field was found
              with 2 types that can't be unified because they do not
              respect the correct type constructor arity.

    {b Rem} : Exported outside this module.
              Note that I can't really see how this coudl happen...    *)
(* ******************************************************************* *)
exception Not_subspecies_arity_mismatch of
  ((** The collection name that should be a subspecies of the one below. *)
   Types.type_collection *
   (** The collection name that should be an overspecies of the one above. *)
   Types.type_collection *
   Parsetree.vname *    (** Name of the field. *)
   Types.type_name *    (** Name of the type constructor. *)
   int *                (** First arity the type constructor was used with. *)
   int *                (** Second arity the type constructor was used with. *)
    Location.t)         (** Related location when the error occured. *)
;;



(* ******************************************************************* *)
(** {b Descr} : During subspecies relation checking, a field was not
              found in the species signature that is considered as the
              subspecies.

    {b Rem} : Exported outside this module.                            *)
(* ******************************************************************* *)
exception Not_subspecies_missing_field of
  ((** The collection name that should be a subspecies of the one below. *)
   Types.type_collection *
   (** The collection name that should be an overspecies of the one above. *)
   Types.type_collection *
   Parsetree.vname *     (** Field name that was not found. *)
   Location.t)           (** Related location when the error occured. *)
;;



(* ******************************************************************* *)
(** {b Descr} : During a parameterized species application, the number
              of provided arguments is incorrect compared to the
              number of expected arguments.

    {b Rem} : Exported outside this module.                            *)
(* ******************************************************************* *)
exception Parameterized_species_arity_mismatch of
  string    (** The message to insert in the error message: "many" or "few". *)
;;



(* *********************************************************************** *)
(** {b Descr} : During collection creation, it appears that the collection
              can't be created because at leat one field is only declared
             and not defined.

    {b Rem} : Exported outside this module.                                *)
(* *********************************************************************** *)
exception Collection_not_fully_defined of
  (Parsetree.qualified_species *  (** The incompletely defined species. *)
   Parsetree.vname)      (** The name of the field missing an implementation. *)
;;


(* ************************************************************************* *)
(** {b Descr} : After generalization, a type scheme contains type variables.
       (either generalized or non generalized). Because in FoCaL methods
       are not even polymorphic, we of course also reject any scheme
       where some polymorphic variable would remain. But because we also
       don't want to have non instanciated variables in a scheme (those
       like OCaml's "'_a") we also reject schemes with non-generalized
       variables. Hence, more globally, we reject schemes containing
       variables.

    {b Rem} : Exported outside this module.                                  *)
(* ************************************************************************* *)
exception Scheme_contains_type_vars of (
  Parsetree.vname *   (** The method's name whose scheme contains variables. *)
  Types.type_scheme * (** The scheme containing the variables. *)
  Location.t)         (** Location where the issue arises in the source. *)
;;



(* ************************************************************************* *)
(** {b Descr} : Datastructure recording the various information required
              and propagated during the type inference. It is much more
              convenient to group the various flags and stuff needed than
              passing them all the time as arguments of each recursive call.
              This datastructure serves especially this purpose.

    {b Rem} : Not exported outside this module.                              *)
(* ************************************************************************* *)
type typing_context = {
  (** The name of the currently analysed compilation unit (i.e. the name
      of the file without extension and not capitalized). *)
  current_unit : Types.fname ;
  (** The name of the current species if relevant. *)
  current_species : Parsetree.qualified_species option ;
  (** Optional type Self is known to be equal to. *)
  self_manifest : Types.type_simple option ;
  (** Mapping between 'variables [vname]s and the [simple_type] they are
      bound to. Used when creating a polymorphic type definition. *)
  tyvars_mapping : (Parsetree.vname * Types.type_simple) list
}
;;



(* ******************************************************************* *)
(* typing_context -> Env.Env.ScopeInformation.t ->                     *)
(*   Parsetree.type_expr -> Types.type_simple                          *)
(** {b Descr} : Translates a type expression into a [type_simple].
                Variable are translated according to the mapping found
                inside the current context. Hence, in case this
                function is used to create the body type of a type
                definition, if the definition is polymorphic, the
                parameter-variables must already exist inside  the
                mapping.

    {b Rem} : Not exported outside this module.                        *)
(* ******************************************************************* *)
let rec typecheck_type_expr ctx env ty_expr =
  let final_ty =
    (match ty_expr.Parsetree.ast_desc with
     | Parsetree.TE_ident ident ->
         (begin
         let ident_ty =
           match ident.Parsetree.ast_desc with
            | Parsetree.I_local ((Parsetree.Vqident _) as variable_qname) ->
                (begin
                (* Just handle the special where [ident] is a type variable. *)
                try List.assoc variable_qname ctx.tyvars_mapping
                with Not_found ->
                  raise
                    (Unbound_type_variable
                       (ident.Parsetree.ast_loc, variable_qname))
                end)
            | _ ->
                (* Case of all 0-ary other user-defined type constructors. *)
                let ty_descr =
                  Env.TypingEnv.find_type
                    ~loc: ident.Parsetree.ast_loc
                    ~current_unit: ctx.current_unit ident env in
                if ty_descr.Env.TypeInformation.type_arity <> 0 then
                  raise
                    (Bad_type_arity
                       (ident, ty_descr.Env.TypeInformation.type_arity, 0))
                else
                  Types.specialize ty_descr.Env.TypeInformation.type_identity in
         (* Record the type in the AST node of the [ident]. *)
         ident.Parsetree.ast_type <- Parsetree.ANTI_type ident_ty ;
         ident_ty
         end)
     | Parsetree.TE_fun (ty_expr1, ty_expr2) ->
         Types.type_arrow
           (typecheck_type_expr ctx env ty_expr1)
           (typecheck_type_expr ctx env ty_expr2)
     | Parsetree.TE_app (ty_cstr_ident, args_ty_exprs) ->
         (begin
         let ty_descr =
           Env.TypingEnv.find_type
             ~loc: ty_cstr_ident.Parsetree.ast_loc
             ~current_unit: ctx.current_unit ty_cstr_ident env in
         (* Record in the AST node of the type of the [ty_cstr_ident]. *)
         ty_cstr_ident.Parsetree.ast_type <-
           Parsetree.ANTI_scheme ty_descr.Env.TypeInformation.type_identity ;
         (* Check the type constructor's arity. *)
         let args_ty_len = List.length args_ty_exprs in
         if args_ty_len <> ty_descr.Env.TypeInformation.type_arity then
           raise
             (Bad_type_arity
                (ty_cstr_ident, ty_descr.Env.TypeInformation.type_arity,
                 args_ty_len)) ;
         (* Synthetise the types for the arguments. *)
         let args_ty = List.map (typecheck_type_expr ctx env) args_ty_exprs in
         (* Now get a fresh instance of the type's type scheme in which *)
         (* the parameters are directly instanciated by the effective   *)
         (* arguments the sum type constructor is applied to.           *)
         Types.specialize_with_args
           ty_descr.Env.TypeInformation.type_identity args_ty
         end)
     | Parsetree.TE_prod ty_exprs ->
         let tys = List.map (typecheck_type_expr ctx env) ty_exprs in
         Types.type_tuple tys
     | Parsetree.TE_self -> Types.type_self ()
     | Parsetree.TE_prop -> Types.type_prop ()
     | Parsetree.TE_paren inner -> typecheck_type_expr ctx env inner) in
  (* Store the type information in the expression's node. *)
  ty_expr.Parsetree.ast_type <- Parsetree.ANTI_type final_ty ;
  final_ty
;;



(* ******************************************************************* *)
(* typing_context -> Env.Env.ScopeInformation.t ->                     *)
(*   Parsetree.rep_type_def -> Types.type_simple                       *)
(** {b Descr} : Translates a rep type expression into a [type_simple].
        This function behaves exactly like [typecheck_type_expr].
        Variable are translated according to the mapping found inside
        the current context. Hence, in case this function is used to
        create the body type of a type definition, if the definition
        is polymorphic, the parameter-variables must already exist
        inside the mapping.

    {b Rem} : Not exported outside this module.                        *)
(* ******************************************************************* *)
let rec typecheck_rep_type_def ctx env rep_type_def =
  let final_ty =
    (match rep_type_def.Parsetree.ast_desc with
     | Parsetree.RTE_ident ident ->
         (begin
         let ident_ty =
           (match ident.Parsetree.ast_desc with
            | Parsetree.I_local ((Parsetree.Vqident _) as variable_qname) ->
                (begin
                (* Just handle the special where [ident] is a type variable.  *)
                (* Note that for a "rep" type because polymorphism is not     *)
                (* allowed, this should never be used. We could safely raise  *)
                (* an error. But, in order to keep this function clean and    *)
                (* smooth, we will enable this and perform a non-polymorphism *)
                (* test later on the obtained type. Anyway this kind of test  *)
                (* is not only required for "rep", but also for all the other *)
                (* methods (they can't either be polymorphic).                *)
                try List.assoc variable_qname ctx.tyvars_mapping
                with Not_found ->
                  raise
                    (Unbound_type_variable
                       (ident.Parsetree.ast_loc, variable_qname))
                end)
            | _ ->
                (* Case of all 0-ary other user-defined type constructors. *)
                let ty_descr =
                  Env.TypingEnv.find_type
                    ~loc: ident.Parsetree.ast_loc
                    ~current_unit: ctx.current_unit ident env in
                if ty_descr.Env.TypeInformation.type_arity <> 0 then
                  raise
                    (Bad_type_arity
                       (ident, ty_descr.Env.TypeInformation.type_arity, 0))
                else
                  Types.specialize
                    ty_descr.Env.TypeInformation.type_identity) in
         (* Record the type in the AST node of the [ident]. *)
         ident.Parsetree.ast_type <- Parsetree.ANTI_type ident_ty ;
         ident_ty
         end)
     | Parsetree.RTE_fun (ty_expr1, ty_expr2) ->
         Types.type_arrow
           (typecheck_rep_type_def ctx env ty_expr1)
           (typecheck_rep_type_def ctx env ty_expr2)
     | Parsetree.RTE_app (ty_cstr_ident, args_ty_exprs) ->
         let ty_descr =
           Env.TypingEnv.find_type
             ~loc: ty_cstr_ident.Parsetree.ast_loc
             ~current_unit: ctx.current_unit ty_cstr_ident env in
         (* Check the type constructor's arity. *)
         let args_ty_len = List.length args_ty_exprs in
         if args_ty_len <> ty_descr.Env.TypeInformation.type_arity then
           raise
             (Bad_type_arity
        (ty_cstr_ident, ty_descr.Env.TypeInformation.type_arity,
         args_ty_len));
         (* Synthetise the types for the arguments. *)
         let args_ty =
           List.map (typecheck_rep_type_def ctx env) args_ty_exprs in
         (* Now get a fresh instance of the type's type scheme in which *)
         (* the parameters are directly instanciated by the effective   *)
         (* arguments the sum type constructor is applied to.           *)
         Types.specialize_with_args
           ty_descr.Env.TypeInformation.type_identity args_ty
     | Parsetree.RTE_prod (ty_exprs) ->
         let tys = List.map (typecheck_rep_type_def ctx env) ty_exprs in
         Types.type_tuple tys
     | Parsetree.RTE_paren inner -> typecheck_rep_type_def ctx env inner) in
  (* Store the type information in the expression's node. *)
  rep_type_def.Parsetree.ast_type <- Parsetree.ANTI_type final_ty;
  final_ty
;;



(* ************************************************************************* *)
(* Parsetree.type_expr list -> (Parsetree.vname * Types.type_simple) list    *)
(** {b Descr} : Create a fresh variable mapping automatically variables in
              the types as generalized. This is used when one creates a
              type structure from an external value's type expression.
              In effect, in such a context, variables in the type are
              implicitely considered as generalized because the type
              constraint annotating the external value does not show
              explicitly "forall-bound-variables".
              Hence, in an external value definition like:
              [external value foc_error : string -> 'a = ...]
              the ['a] must be considered as generalized, then when
              typechecking this definition the context must have a variable
              mapping where ['a] is known. Using the present function, one
              can build such a mapping.

    {b Rem} : Not exported outside this module.                              *)
(* ************************************************************************* *)
let make_implicit_var_mapping_from_type_exprs type_expressions =
  let mapping = ref [] in
  let rec rec_make texpr =
    match texpr.Parsetree.ast_desc with
    | Parsetree.TE_ident ident ->
        (begin
         match ident.Parsetree.ast_desc with
         | Parsetree.I_local ((Parsetree.Vqident _) as variable_qname) ->
             (* Just handle the special case where *)
             (* the ident is a type variable.      *)
             if not (List.mem_assoc variable_qname !mapping) then
               mapping :=
                 (variable_qname, Types.type_variable ()) :: !mapping
         | _ -> ()
         end)
    | Parsetree.TE_fun (ty_expr1, ty_expr2) ->
        rec_make ty_expr1;
        rec_make ty_expr2
    | Parsetree.TE_app (_, args_ty_exprs) -> List.iter rec_make args_ty_exprs
    | Parsetree.TE_prod ty_exprs -> List.iter rec_make ty_exprs
    | Parsetree.TE_self
    | Parsetree.TE_prop -> ()
    | Parsetree.TE_paren inner -> rec_make inner in
  (* **************** *)
  (* Now really work. *)
  mapping := [];
  List.iter rec_make type_expressions;
  !mapping
;;



(* ************************************************************************* *)
(* Parsetree.prop -> (string * Types.type_simple) list                       *)
(** {b Descr} : Create a fresh variable mapping automatically variables in
              the type parts of a [prop] as generalized. This is used when
              one creates a type structure from a theorem expression.
              In effect, in such a context, variables in the type are
              implicitely considered as generalized because the type
              constraint annotating the theorem does not show
              explicitly "forall-bound-variables".
              Hence, in an theorem definition like:
              [theorem beq_refl : all x in 'a, ...]
              the ['a] must be considered as generalized, then when
              typechecking this definitionn the context must have a variable
              mapping where ['a] is known. Using the present function, one
              can build such a mapping.

    {b Rem} : Not exported outside this module.                              *)
(* ************************************************************************* *)
let make_implicit_var_mapping_from_prop prop_expression =
  let mapping = ref [] in
  let rec rec_make pexpr =
    match pexpr.Parsetree.ast_desc with
    | Parsetree.Pr_forall (_, ty, prop)
    | Parsetree.Pr_exists (_, ty, prop) ->
        (* First recover the mapping induced by the type expression. *)
        let mapping_from_ty = make_implicit_var_mapping_from_type_exprs [ty] in
        (* Assuming the current mapping doesn't contain doubles, we *)
        (* extend it by the one got from the  type expression.      *)
        mapping :=
          Handy.list_concat_uniq_custom_eq
            (fun (n, _) (n', _) -> n = n') mapping_from_ty !mapping;
        rec_make prop
    | Parsetree.Pr_imply (prop1, prop2)
    | Parsetree.Pr_or (prop1, prop2)
    | Parsetree.Pr_and (prop1, prop2)
    | Parsetree.Pr_equiv (prop1, prop2) ->
        rec_make prop1;
        rec_make prop2
    | Parsetree.Pr_not prop
    | Parsetree.Pr_paren prop -> rec_make prop
    | Parsetree.Pr_expr _ ->
        (* Inside expressions type variable must be bound by the previous *)
        (* parts of the prop ! Hence, do not continue searching inside.   *)
        () in
  rec_make prop_expression;
  !mapping
;;



(* ********************************************************************* *)
(* current_unit:Types.fname -> Env.TypingEnv.t -> Parsetree.expr -> bool *)
(** {b Descr} : If returns [true] then one can generalise the expression
             passed as argument.

    {b Rem} : Not exported outside this module.                          *)
(* ********************************************************************* *)
let rec is_non_expansive ~current_unit env expr =
  match expr.Parsetree.ast_desc with
  | Parsetree.E_const _ -> true
  | Parsetree.E_var _ -> true
  | Parsetree.E_let (let_def, body) ->
      List.for_all
        (fun binding ->
         let bound_expr = binding.Parsetree.ast_desc.Parsetree.b_body in
         (* Be careful. Consider the comment in the function    *)
         (* [typecheck_let_definition] dealing with body hiding *)
         (* the functional aspect of the whole definition.      *)
         binding.Parsetree.ast_desc.Parsetree.b_params <> [] ||
         is_non_expansive ~current_unit env bound_expr)
        let_def.Parsetree.ast_desc.Parsetree.ld_bindings &&
      is_non_expansive ~current_unit env body
  | Parsetree.E_fun _ -> true
  | Parsetree.E_tuple exprs ->
      List.for_all (is_non_expansive ~current_unit env) exprs
  | Parsetree.E_record lbl_exp_list ->
      List.for_all
        (fun (lbl, e) ->
          let lbl_descr =
            Env.TypingEnv.find_label
              ~loc: expr.Parsetree.ast_loc ~current_unit lbl env in
          lbl_descr.Env.TypeInformation.field_mut =
            Env.TypeInformation.FM_immutable &&
          is_non_expansive ~current_unit env e)
        lbl_exp_list
  | Parsetree.E_record_access (e, _) -> is_non_expansive ~current_unit env e
  | Parsetree.E_constr (_, exprs) ->
      List.for_all (is_non_expansive ~current_unit env) exprs
  | Parsetree.E_paren e -> is_non_expansive ~current_unit env e
  | Parsetree.E_external _ ->
      (* [Unsure]. Needed to make external functions generalized but should   *)
      (* be guarded by something because in fact the real external definition *)
      (* may indeed by EXPANSIVE !                                            *)
      true
  | _ -> false
;;



(* ******************************************************************** *)
(* Parsetree.constant -> Types.type_simple                              *)
(** {b Descr} : Infers the type of a constant. Records this type in the
              AST node and return the type.

    {b Rem} : Not exported outside this module.                         *)
(* ******************************************************************** *)
let typecheck_constant constant_desc =
  let ty =
    match constant_desc.Parsetree.ast_desc with
    | Parsetree.C_int _ -> Types.type_int ()
    | Parsetree.C_float _ -> Types.type_float ()
    | Parsetree.C_bool _ -> Types.type_bool ()
    | Parsetree.C_string _ -> Types.type_string ()
    | Parsetree.C_char _ -> Types.type_char () in
  constant_desc.Parsetree.ast_type <- Parsetree.ANTI_type ty ;
  ty
;;



(* ********************************************************************* *)
(* typing_context -> Env.TypingEnv.t -> Parsetree.pattern ->             *)
(*   Types.type_simple * (Parsetree.vname * Types.type_scheme) list      *)
(** {b Descr} : Infers the type of a [pattern]. Records this type in the
              AST node and return the type and a list of bindings
              that map the variables found in the pattern and their
              types.

    {b Rem} : Not exported outside this module.                          *)
(* ********************************************************************* *)
let rec typecheck_pattern ctx env pat_desc =
  (* First, get the pattern's type and induced bindings. *)
  let (final_ty, bindings) =
    (match pat_desc.Parsetree.ast_desc with
     | Parsetree.P_const cst -> ((typecheck_constant cst), [])
     | Parsetree.P_var var ->
         let var_ty = Types.type_variable () in
         (var_ty, [ (var, (Types.trivial_scheme var_ty)) ])
     | Parsetree.P_as (pat, alias) ->
         let (ty, bindings) = typecheck_pattern ctx env pat in
         (ty, ((alias, (Types.trivial_scheme ty)) :: bindings))
     | Parsetree.P_wild ->
         let var_ty = Types.type_variable () in
         (var_ty, [])
     | Parsetree.P_constr (cstr_name, pats) ->
         (* Find a specialization of the constructor's type scheme. *)
         let cstr_decl =
           Env.TypingEnv.find_constructor
             ~loc: cstr_name.Parsetree.ast_loc
             ~current_unit: ctx.current_unit cstr_name env in
         (match pats, cstr_decl.Env.TypeInformation.cstr_arity with
          | [], Env.TypeInformation.CA_zero ->
              let cstr_ty =
                Types.specialize cstr_decl.Env.TypeInformation.cstr_scheme in
              (cstr_ty, [])
          | nempty_pats, Env.TypeInformation.CA_one ->
              let cstr_ty =
                Types.specialize cstr_decl.Env.TypeInformation.cstr_scheme in
              (* Recover the type of the sub-patterns by typechecking an  *)
              (* artificial tuple argument compound of the sub-patterns.  *)
              (* Proceed this way EVEN if there is ONE argument. We then  *)
              (* in effect have degenerated tuples with only 1 component. *)
              let (cstr_arg_ty, sub_bindings) =
                typecheck_pattern ctx env
                { pat_desc with
                  Parsetree.ast_desc = Parsetree.P_tuple nempty_pats } in
              (* Constructeurs being functions, we will unify [cstr_type]   *)
              (* with an arrow type to ensure that it is really one and     *)
              (* to ensure the arguments types and extract the result type. *)
              let unified_cstr_ty =
                Types.unify
                  ~loc: pat_desc.Parsetree.ast_loc
                  ~self_manifest: ctx.self_manifest
                  (Types.type_arrow cstr_arg_ty (Types.type_variable ()))
                  cstr_ty in
              (Types.extract_fun_ty_result unified_cstr_ty, sub_bindings)
          | _, _ ->
              (* Just raise the exception with the right expected arity. *)
              raise
                (Bad_sum_type_constructor_arity
                   (cstr_name, cstr_decl.Env.TypeInformation.cstr_arity)))
     | Parsetree.P_record label_n_patterns ->
         (* Type for this pattern. Will be instanciated by side effect. *)
         let whole_pat_ty = ref (Types.type_variable ()) in
         (* Infer type of eack sub-pattern. *)
         let infer_sub_pat (lbl, pat) =
           (* Get bindings and sub-pattern type. *)
           let (sub_pat_ty, bnds) = typecheck_pattern ctx env pat in
           let lbl_desc =
             Env.TypingEnv.find_label
               ~loc: pat.Parsetree.ast_loc
               ~current_unit: ctx.current_unit lbl env in
           (* Get the related label type. *)
           let lbl_ty =
             Types.specialize
               lbl_desc.Env.TypeInformation.field_scheme in
           (* Now, ensure the 2 sub-pattners types are compatible and *)
           (* that the resulting record type for the whole pattern is *)
           (* consistent.                                             *)
           let unified_field_ty =
             Types.unify
               ~loc: pat.Parsetree.ast_loc
               ~self_manifest: ctx.self_manifest lbl_ty
               (Types.type_arrow sub_pat_ty !whole_pat_ty) in
           whole_pat_ty := Types.extract_fun_ty_result unified_field_ty ;
           (* Just returns the bindings. *)
           bnds in
         let bindings =
           List.flatten
             (List.map infer_sub_pat label_n_patterns) in
         (!whole_pat_ty, bindings)
     | Parsetree.P_tuple pats ->
         let (tys, bindings) =
           List.split (List.map (typecheck_pattern ctx env) pats) in
         let ty = Types.type_tuple tys in
         (ty, (List.flatten bindings))
     | Parsetree.P_paren pat -> typecheck_pattern ctx env pat) in
  (* And now, store the type information inside the node. *)
  pat_desc.Parsetree.ast_type <- Parsetree.ANTI_type final_ty ;
  (* Return both infered type and bindings. *)
  (final_ty, bindings)
;;





(* Does not make any assumption. Crudely returns a fresh type variable. *)
let typecheck_external_expr ext_expr =
  let ty = Types.type_variable () in
  (* A somewhat taste of magic obj... *)
  ext_expr.Parsetree.ast_type <- Parsetree.ANTI_type ty ;
  ty
;;



(* *********************************************************************** *)
(* typing_context -> Env.TypingEnv.t -> Parsetree.fact -> unit             *)
(** {b Descr} : Typechecks a [fact]. Because the type of a fact is not
            relevant in FoCaL, this function does not returns any type.
            Its only goal is to verify the type of the AST-sub-expressions
            where it is relevant and to screw this type in the [ast_type]
            field of these AST-nodes (i.e especially throug [expr_ident]s.

    {b Rem} : Not exported outside this module.                            *)
(* *********************************************************************** *)
let typecheck_fact ctx env fact =
  (* No relevant type information to insert in the AST node. *)
  fact.Parsetree.ast_type <- Parsetree.ANTI_non_relevant ;
  match fact.Parsetree.ast_desc with
   | Parsetree.F_def expr_idents
   | Parsetree.F_property expr_idents ->
       List.iter
         (fun expr_ident ->
           let var_scheme =
             Env.TypingEnv.find_value
               ~loc: expr_ident.Parsetree.ast_loc
               ~current_unit: ctx.current_unit expr_ident env in
           let ident_ty = Types.specialize var_scheme in
           (* Record the ident's type in the AST node. *)
           expr_ident.Parsetree.ast_type <- Parsetree.ANTI_type ident_ty)
         expr_idents
   | Parsetree.F_hypothesis _ -> ()
   | Parsetree.F_node _ -> ()
;;



(* **************************************************************** *)
(* Parsetree.vname -> Env.TypeInformation.species_field list ->     *)
(*   Env.TypeInformation.species_field list -> unit                 *)
(* {b Descr} : Checks if the 2 lists of fields contain methods
           names that overlap. If so then raises en exception
           [Method_multiply_defined], else silently returns.

   {Rem} : Not exported outside this module.                        *)
(* **************************************************************** *)
let ensure_methods_uniquely_defined current_species l1 l2 =
  (* Just a local flattening function... *)
  let local_flat_fields fields =
    List.fold_right
      (fun field accu ->
        match field with
        | Env.TypeInformation.SF_sig (_, v, _)
        | Env.TypeInformation.SF_let (_, v, _, _, _)
        | Env.TypeInformation.SF_theorem (_, v, _, _, _)
        | Env.TypeInformation.SF_property (_, v, _, _) -> v :: accu
        | Env.TypeInformation.SF_let_rec l ->
            let l' = List.map (fun (_, v, _, _, _) -> v) l in
            l' @ accu)
      fields [] in
  (* Now get the flat list of all the methods names. *)
  let flat_l1 = local_flat_fields l1 in
  let flat_l2 = local_flat_fields l2 in
  (* And check for no overlap. *)
  List.iter
    (fun name1 ->
      List.iter
        (fun name2 ->
          if name1 = name2 then
            raise (Method_multiply_defined (name1, current_species)))
        flat_l2)
    flat_l1
;;



(* ************************************************************************ *)
(* typing_context -> Env.TypingEnv.t -> Parsetree.expr -> Types.type_simple *)
(** {b Descr} : Infers the type o an [expr] and assign it by side effect in
              the [ast_type] field of the [expr] node.

    {b Rem} : Not exported outside this module.                             *)
(* ************************************************************************ *)
let rec typecheck_expr ctx env initial_expr =
  let final_ty =
    (match initial_expr.Parsetree.ast_desc with
     | Parsetree.E_self -> Types.type_self ()
     | Parsetree.E_const cst -> typecheck_constant cst
     | Parsetree.E_fun (arg_vnames, e_body) ->
         (* Create the type for each argument .*)
         let args_ty = List.map (fun _ -> Types.type_variable ()) arg_vnames in
         (* Build the environment extended by these arguments and types. *)
         (* Preferably use a fold_left instead of a fold_right, this way *)
         (* arguments are "cons-ed" in the environment in their order of *)
         (* declaration. Because arguments can't depend on each other,   *)
         (* that's not a big matter, but that's cleaner...               *)
         let extended_env =
           List.fold_left2
             (fun accu_env arg_name arg_ty ->
               (* Do not generalize argument types ! No Mu-rule yet ! *)
               Env.TypingEnv.add_value
         arg_name (Types.trivial_scheme arg_ty) accu_env)
             env arg_vnames args_ty in
         (* Now, typecheck the body i nthe new environment. *)
         let ty_body = typecheck_expr ctx extended_env e_body in
         (* Remains to build the final functional type. And do not *)
         (* fold_left, otherwise you'll get a mirrored type !      *)
         List.fold_right
           (fun arg_ty accu_ty -> Types.type_arrow arg_ty accu_ty)
           args_ty ty_body
     | Parsetree.E_var ident ->
         (* E_var is never "self" because "self" is a dedicated case. *)
         (* Now, don't bother with the search order, this has already *)
         (* be done by both the scoping and the environment build     *)
         (* process. As reminder, lookup will naturally find the      *)
         (* ident among local identifiers, in-params, is-params,      *)
         (* inheritance and finally global identifiers.               *)
         let var_scheme =
           Env.TypingEnv.find_value
             ~loc: ident.Parsetree.ast_loc
             ~current_unit: ctx.current_unit ident env in
         let ident_ty = Types.specialize var_scheme in
         (* Record the [ident]'s type in its AST node. *)
         ident.Parsetree.ast_type <- Parsetree.ANTI_type ident_ty ;
         ident_ty
     | Parsetree.E_app (functional_expr, args_exprs) ->
         let fun_ty = typecheck_expr ctx env functional_expr in
         let ty_exprs = List.map (typecheck_expr ctx env) args_exprs in
         List.fold_left
           (fun accu_fun_ty arg_ty ->
            (* Temporary functionnal type to unify with *)
            (* the type of the current applicator.      *)
            let tmp_fun_ty =
              Types.type_arrow arg_ty (Types.type_variable ()) in
            let unified_fun_ty =
              Types.unify
                ~loc: initial_expr.Parsetree.ast_loc
                ~self_manifest: ctx.self_manifest tmp_fun_ty accu_fun_ty in
            (* The result is the positive part of the arrow. *)
            Types.extract_fun_ty_result unified_fun_ty)
           fun_ty
           ty_exprs
     | Parsetree.E_constr (cstr_ident, exprs) ->
         let cstr_decl =
           Env.TypingEnv.find_constructor
             ~loc: cstr_ident.Parsetree.ast_loc
             ~current_unit: ctx.current_unit cstr_ident env in
         (match (exprs, cstr_decl.Env.TypeInformation.cstr_arity) with
          | ([], Env.TypeInformation.CA_zero) ->
              (* Just get an instance of the constructor's type scheme. *)
              let ty =
                Types.specialize cstr_decl.Env.TypeInformation.cstr_scheme in
              (* Record the type in the AST node of the [cstr_ident]. *)
              cstr_ident.Parsetree.ast_type <- Parsetree.ANTI_type ty ;
              ty
          | (_, Env.TypeInformation.CA_one) ->
              (* The constructor must be viewed as a function. *)
              let tys = List.map (typecheck_expr ctx env) exprs in
              (* Get an instance of the constructor's type scheme. *)
              let cstr_ty =
                Types.specialize cstr_decl.Env.TypeInformation.cstr_scheme in
              (* Record the type in the AST node of the [cstr_ident]. *)
              cstr_ident.Parsetree.ast_type <- Parsetree.ANTI_type cstr_ty ;
              (* Build the shadow tuple type as the *)
              (* real argument of the constructor.  *)
              let cstr_arg_ty = Types.type_tuple tys in
              (* And simulate an application. *)
              let unified_cstr_ty =
                Types.unify
                  ~loc: initial_expr.Parsetree.ast_loc
                  ~self_manifest: ctx.self_manifest
                  cstr_ty
                  (Types.type_arrow cstr_arg_ty (Types.type_variable ())) in
              Types.extract_fun_ty_result unified_cstr_ty
          | (_, _) ->
              raise
                (Bad_sum_type_constructor_arity
                   (cstr_ident, cstr_decl.Env.TypeInformation.cstr_arity)))
     | Parsetree.E_match (matched_expr, bindings) ->
         let matched_expr_ty = ref (typecheck_expr ctx env matched_expr) in
         (* Let's get a fresh type accumulator  *)
         (* to unify the clauses' bodies types. *)
         let result_ty = ref (Types.type_variable ()) in
         (* Process each clause of the match. *)
         List.iter
           (fun (pat, expr) ->
             (* Infer the type and bindings induced by the pattern. *)
             let (pat_ty, bnds) = typecheck_pattern ctx env pat in
             (* Ensure the matched expression and the pattern have the *)
             (* same type always keep the type where Self is prefered. *)
             matched_expr_ty :=
               Types.unify
                 ~loc: initial_expr.Parsetree.ast_loc
                 ~self_manifest: ctx.self_manifest !matched_expr_ty pat_ty;
             (* Extend the environment with the pattern type bindings. *)
             let env' =
               List.fold_left
                 (fun accu_env (id, ty_scheme) ->
                  Env.TypingEnv.add_value id ty_scheme accu_env)
                 env bnds in
             (* Infer the type of the match clause's body. *)
             let clause_ty = typecheck_expr ctx env' expr in
             (* Force every bodies to have the same result type  *)
             (* and always keep the type where Self is prefered. *)
             result_ty :=
               Types.unify
                 ~loc: initial_expr.Parsetree.ast_loc
                 ~self_manifest: ctx.self_manifest !result_ty clause_ty)
           bindings;
         (* Return the type of the bodies' clauses. *)
         !result_ty
     | Parsetree.E_if (e_cond, e_then, e_else) ->
         let ty_cond = typecheck_expr ctx env e_cond in
         (* Ensure the condition is a boolean. *)
         ignore
           (Types.unify
              ~loc: initial_expr.Parsetree.ast_loc
              ~self_manifest: ctx.self_manifest ty_cond (Types.type_bool ()));
         (* Typecheck the "then" expression. *)
         let ty_then = typecheck_expr ctx env e_then in
         let ty_else = typecheck_expr ctx env e_else in
         (* Enforce both branches to have the same type. *)
         Types.unify
           ~loc: initial_expr.Parsetree.ast_loc
           ~self_manifest: ctx.self_manifest ty_then ty_else
     | Parsetree.E_let (let_def, in_expr) ->
         (* Don't increase level, this will be done in the let inference. *)
         let bindings =
           typecheck_let_definition ~is_a_field: false ctx env let_def in
         (* Let's build the environment for typing the ending expression. *)
         let env' =
           List.fold_left
             (fun accu_env (id, ty_scheme) ->
              Env.TypingEnv.add_value id ty_scheme accu_env)
             env bindings in
         typecheck_expr ctx env' in_expr
     | Parsetree.E_record fields -> typeckeck_record_expr ctx env fields None
     | Parsetree.E_record_access (expr, label) ->
         let ty_expr = typecheck_expr ctx env expr in
         let label_desc =
           Env.TypingEnv.find_label
             ~loc: initial_expr.Parsetree.ast_loc
             ~current_unit: ctx.current_unit label env in
         (* Just remind that labels are types as functions of type     *)
         (* "type of the field as seen by user -> type od the record". *)
         let label_ty =
           Types.specialize label_desc.Env.TypeInformation.field_scheme in
         let unified_label_ty =
           Types.unify
             ~loc: initial_expr.Parsetree.ast_loc
             ~self_manifest: ctx.self_manifest
             (Types.type_arrow (Types.type_variable ()) ty_expr) label_ty in
         Types.extract_fun_ty_arg unified_label_ty
     | Parsetree.E_record_with (with_expr, fields) ->
         typeckeck_record_expr ctx env fields (Some with_expr)
     | Parsetree.E_tuple exprs ->
         assert (exprs <> []);  (* Just in case. O-ary tuple is non-sense ! *)
         let tys = List.map (typecheck_expr ctx env) exprs in
         Types.type_tuple tys
     | Parsetree.E_external ext_expr -> typecheck_external_expr ext_expr
     | Parsetree.E_paren expr -> typecheck_expr ctx env expr) in
  (* Store the type information in the expression's node. *)
  initial_expr.Parsetree.ast_type <- Parsetree.ANTI_type final_ty ;
  final_ty



(* ****************************************************************** *)
(* Env.TypingEnv.t -> (Types.label_name * Parsetree.expr) list ->     *)
(*   Parsetree.expr option -> Types.type_simple                       *)
(** {b Descr} : Performs type inference on record expressions with or
              without "with" clause. Currently, the labels
              exhaustivity is not checked. It has to be done when
              there is no "with" clause.

    {b Args} :
      - env : The current typing environment.
      - fields : The list of fields values of the record expression.
      - opt_with_expr : The optional "with" clause.

    {b Rem} : Not exported outside this module.                      *)
(* ***************************************************************** *)
and typeckeck_record_expr ctx env fields opt_with_expr =
  (* At then end, must be the type of the host of all these labels. *)
  let result_ty = ref (Types.type_variable ()) in
  (* Typecheck the "with" construct if any. *)
  (match opt_with_expr with
   | None ->
       (* To disapear once implemented ! *)
       Format.eprintf "Labels exhaustivity not checked on record expression.@\n"
   | Some expr ->
       let expr_ty = typecheck_expr ctx env expr in
       result_ty :=
         Types.unify
           ~loc: expr.Parsetree.ast_loc
           ~self_manifest: ctx.self_manifest expr_ty !result_ty) ;
  (* Now proceed with the labels.                               *)
  (* Just remind that labels are types as functions of type     *)
  (* "type of the field as seen by user -> type od the record". *)
  List.iter
    (fun (label, expr) ->
      let expr_ty = typecheck_expr ctx env expr in
      let lbl_descr =
        Env.TypingEnv.find_label
          ~loc: expr.Parsetree.ast_loc
          ~current_unit: ctx.current_unit label env in
      (* Get the functionnal type of this field. *)
      let field_ty =
        Types.specialize lbl_descr.Env.TypeInformation.field_scheme in
      (* Record the type of the field in the AST node of the [label_ident]. *)
      label.Parsetree.ast_type <- Parsetree.ANTI_type field_ty ;
       (* Unify the result type by side effect. *)
      let unified_field_ty =
        Types.unify
          ~loc: expr.Parsetree.ast_loc ~self_manifest: ctx.self_manifest
          (Types.type_arrow expr_ty !result_ty) field_ty in
      result_ty := Types.extract_fun_ty_result unified_field_ty)
    fields ;
  !result_ty



(* ************************************************************************ *)
(* is_a_field: bool -> typing_context -> Env.TypingEnv.t ->                 *)
(*   Parsetree.let_def -> (Parsetree.vname * Types.type_scheme) list        *)
(** {b Descr} : Infers the list of bindings induced by the let-def and that
                will extend the current typing environment.
                Because methods cannot be polymorphic (c.f. Virgile
                Prevosto's Phd section 3.3, page 24) the parameter
                [~is_a_field] permits to know if we must generalize
                or not the let bound identifiers, and even more, if the
                scheme must be down-leveled to 0 or not. If [~is_a_field]
                is [true], then the bound identifiers must NOT be
                generalized and even more, in order to be never
                generalizable (for instance in another species where the
                use of this ident is unfortunately done at the same
                binding level) the scheme's body must be fully toggled
                with a level equal to 0 ! This way, the obtained scheme
                will not be polymorphic forever.
                When this function is called from under a field definition,
                then this flag must obviously be [true].

    {b Rem} : Not exported outside this module.                             *)
(* ************************************************************************ *)
and typecheck_let_definition ~is_a_field ctx env let_def =
  (* A [let_definition] doesn't really has a type. Record in the AST node. *)
  let_def.Parsetree.ast_type <- Parsetree.ANTI_non_relevant ;
  let let_def_descr = let_def.Parsetree.ast_desc in
  (* Get information to possibly build the pre-environment, *)
  (* i.e. the induced environment bindings between idents   *)
  (* and types and if they can be generalised or not.       *)
  let pre_env_info =
    List.map
      (fun { Parsetree.ast_desc = binding_desc } ->
        (* Just use a hack telling that if the expression won't be *)
        (* generalisable, to typecheck it, we don't change the     *)
        (* generalisation level, then we won't generalise it.      *)
        (* Becareful, functions are non_expansive. Because the     *)
        (* structure of the let-def includes the parameters of the *)
        (* bound ident, a fun like [let f (x) = body] will not be  *)
        (* considered as non_expansive if [body] is not because    *)
        (* [body] hides the function because the arguments are     *)
        (* recorded in the [b_params] field. Hence, if the list    *)
        (* [b_params] is not empty, then the bound expression is a *)
        (* a function and is non_expansive whatever the body is.   *)
        if not is_a_field &&
           (binding_desc.Parsetree.b_params <> [] ||
            is_non_expansive
              ~current_unit: ctx.current_unit env
             binding_desc.Parsetree.b_body) then
          (begin
          (* The body expression will be authorised to be generalized. *)
          Types.begin_definition () ;
          let ty = Types.type_variable () in
          Types.end_definition () ;
          (* Say "true" to mean "generalizable" (implies that a  *)
          (* begin/end_definition have been performed) .         *)
          (binding_desc.Parsetree.b_name, ty, true)
          end)
        else
          (begin
          (* The body expression won't be authorised to be generalised. *)
          let ty = Types.type_variable () in
          (* Say "false" to mean "NON-generalisable" (implies that *)
          (* no begin/end_definition have been performed) .        *)
          (binding_desc.Parsetree.b_name, ty, false)
          end))
      let_def_descr.Parsetree.ld_bindings in
  (* Now let's address the bindings bodies ! If the definition is recursive *)
  (* then we extend the current environment with the assumed types.         *)
  let env' =
    if let_def_descr.Parsetree.ld_rec = Parsetree.RF_no_rec then env
    else
      List.fold_left
        (fun accu_env (vname, ty, _) ->
          (* No generalisation (polymorphism) of the function *)
          (* inside its body (that's would be Mu-rule).       *)
          let scheme = Types.trivial_scheme ty in
          Env.TypingEnv.add_value vname scheme accu_env)
        env pre_env_info in
  (* Now typecheck each def's body. *)
  let tmp_env_bindings =
    List.map2
      (fun binding (_, assumed_ty, non_expansive) ->
        let binding_desc =  binding.Parsetree.ast_desc in
        let binding_loc = binding.Parsetree.ast_loc in
        (* Build a type for the arguments of the bound identier if there are *)
        (* some. If they have type constraints, then use it as primary type  *)
        (* instead of using a type variable that we should unify afterwards. *)
        if non_expansive then Types.begin_definition () ;
        let args_tys =
          List.map
            (fun (_, opt_arg_ty_expr) ->
              match opt_arg_ty_expr with
               | None -> Types.type_variable ()
               | Some ty_expr -> typecheck_type_expr ctx env ty_expr)
            binding_desc.Parsetree.b_params in
        if non_expansive then Types.end_definition () ;
        (* Extend the current environment with the arguments *)
        (* of the bound identifier if there are some.        *)
        let local_env =
          List.fold_left2
            (fun accu_env (arg_name, _) arg_ty ->
              Env.TypingEnv.add_value
                arg_name (Types.trivial_scheme arg_ty) accu_env)
                env'
            binding_desc.Parsetree.b_params
            args_tys in
        (* Get all the type constraints from both the params *)
        (* and the body annotations of the definition.       *)
        let all_ty_constraints =
          List.fold_left
            (fun accu (_, tye_opt) ->
              match tye_opt with
              | None -> accu
              | Some tye -> tye :: accu)
            (match binding_desc.Parsetree.b_type with
             | None -> []
             | Some tye -> [tye])
            binding_desc.Parsetree.b_params in
        (* Then, same stuff than for scoping, we add the type variables      *)
        (* appearing in the type contraints to the current variable_mapping. *)
        (* These type variable are in effect implicitely generalized !       *)
        if non_expansive then Types.begin_definition () ;
        let vmap' =
          make_implicit_var_mapping_from_type_exprs all_ty_constraints in
        if non_expansive then Types.end_definition () ;
        let ctx_with_tv_vars_constraints = {
          ctx with tyvars_mapping = vmap' @ ctx.tyvars_mapping } in
        (* Same hack thant above for the variables *)
        (* that must not be generalised.           *)
        if non_expansive then Types.begin_definition () ;
        (* Guess the body's type. *)
        let infered_body_ty =
          typecheck_expr
            ctx_with_tv_vars_constraints local_env
            binding_desc.Parsetree.b_body in
        (* If there is some constraint on this type, then unify with it. *)
        (* But anyway KEEP the constraint for type ! Unification is only *)
        (* there to ensure compatibility between the infered type and    *)
        (* the proposed constraint !                                     *)
        let infered_body_ty_with_constraint =
          (match binding_desc.Parsetree.b_type with
           | None -> infered_body_ty
           | Some ty_expr ->
             let constraint_ty =
               typecheck_type_expr ctx_with_tv_vars_constraints env ty_expr in
             ignore
               (Types.unify
                  ~loc: ty_expr.Parsetree.ast_loc
                  ~self_manifest: ctx_with_tv_vars_constraints.self_manifest
                  constraint_ty infered_body_ty);
             (* As said above, KEEP the constraint as the final type ! *)
             constraint_ty) in
        (* Now, reconstruct the functional type from the body's and args' *)
        (* types. DO NOT fold_left, otherwise the fun type gets mirored ! *)
        (* By the way, be careful to create the type arrow with the right *)
        (* binding level, and especially, not outside the binding level   *)
        (* used to infer the body !!! That's why the end_definition is    *)
        (* done AFTER having created the [complete_ty].                   *)
        let complete_ty =
          List.fold_right
            (fun arg_ty accu_ty -> Types.type_arrow arg_ty accu_ty)
            args_tys
            infered_body_ty_with_constraint in
        if non_expansive then Types.end_definition () ;
        (* Unify the found type with the type that was temporarily assumed. *)
        Types.begin_definition () ;
        let final_ty =
          Types.unify
            ~loc: binding_loc
            ~self_manifest: ctx_with_tv_vars_constraints.self_manifest
            assumed_ty complete_ty in
        Types.end_definition () ;
        (* And finally returns the type binding induced by this definition. *)
        let ty_scheme =
          if non_expansive
          then Types.generalize final_ty
          else Types.trivial_scheme final_ty in
        (* Record the scheme in the AST node of the [binding]. *)
         binding.Parsetree.ast_type <- Parsetree.ANTI_scheme ty_scheme ;
        (binding_desc.Parsetree.b_name, ty_scheme, binding_loc))
      let_def_descr.Parsetree.ld_bindings
      pre_env_info in
  (* Before leaving, if the definition is a species field, we ensure that   *)
  (* no scheme contains generalised or even non generalised type variables. *)
  (* In effect, methods are not polymorphic. And we don't want also to      *)
  (* have methods with partially instanciated types !                       *)
  (* We can't check for this before because of mutual definitions, when     *)
  (* looking at the scheme of a methods, some variables may still be non    *)
  (* instanciated because they will be only once we will have processed the *)
  (* next methods' schemes.                                                 *)
  (* By the way, we make the clean environment binding by discarding the  *)
  (* location information we kept just to be able to pinpoint accurately  *)
  (* the guilty method in case of one would have variables in its scheme. *)
  let env_bindings =
    List.map
      (fun (name, sc, loc) ->
        if is_a_field && Types.scheme_contains_variable_p sc then
          raise (Scheme_contains_type_vars (name, sc, loc));
        (name, sc))
      tmp_env_bindings in
  (* Finally, returns the induced bindings. Note that [Parsetree.binding] *)
  (* and [Parsetree.let_def have an [ast_type] but in this case it has no *)
  (* relevance, so we just leave them [None].                             *)
  env_bindings



(* ************************************************************************* *)
(* typing_context -> Env.TypingEnv.t -> Parsetree.prop ->                    *)
(*   Types.type_simple                                                       *)
(** {b Descr} : Infers the type of a [prop]. This type is always expected
              to be [Prop], hence this inference moslty verifies the right
              types usages inside a property and ensures that the final
              type is really [Prop].
              It finally assign the type by side effect in the [ast_type]
              field of the [prop] node.
              This function takes into account the fact that that carrier
              "rep" must be considered as unknown to prevent def-dependencies
             (C.f. Virgile Prevosto's Phd, section 3.9.4 pages 51 & 52).
             ATTENTION : Because idents (bound by forall and exists) are
             **expressions** and are directly entered in the environment
             with the type prop, the rule of Virgile telling that expressions
             must be of type bool is incorrect. In effect, because idents
             are expressions and are already types prop, unifying them
             with bool wil always fail. Moreover, this fact may leak all
             around the expression type, then one cannot restrict the check
             to only say that an expression-ident typed prop is correct.
             This may flood all around the proposition expression. Then
             in case of an expression, one allows both prop and bool as
             types.
             The [~in_proof] boolean enables to abstract Self only in case
             we infer a [prop]'s type inside a property/theorem definition
             and not in it's proof !
    {b Rem} : Not exported outside this module.                               *)
(* ************************************************************************** *)
and typecheck_prop ~in_proof ctx env prop =
  (* The local recursive function to save carying and changing the context. *)
  let final_ty =
    (match prop.Parsetree.ast_desc with
     | Parsetree.Pr_forall (vnames, t_expr, pr)
     | Parsetree.Pr_exists (vnames, t_expr, pr) ->
         Types.begin_definition ();
         (* Get the couple (name, type) for each defined variable. *)
         let bound_variables =
           let ty = typecheck_type_expr ctx env t_expr in
           List.map (fun vname -> (vname, ty)) vnames in
         (* Now typecheck the prop's body in the extended environment.     *)
         (* Note that as often, th order bindings are inserted in the      *)
         (* environment does not matter since parameters can never depends *)
         (* on each other.                                                 *)
         let env' =
           List.fold_left
             (fun accu_env (th_name, th_type) ->
               let scheme = Types.generalize th_type in
               Env.TypingEnv.add_value th_name scheme accu_env)
             env bound_variables in
         typecheck_prop ~in_proof ctx env' pr
     | Parsetree.Pr_imply (pr1, pr2)
     | Parsetree.Pr_or (pr1, pr2)
     | Parsetree.Pr_and (pr1, pr2)
     | Parsetree.Pr_equiv (pr1, pr2) ->
         let ty1 = typecheck_prop ~in_proof ctx env pr1 in
         let ty2 = typecheck_prop ~in_proof ctx env pr2 in
         ignore
           (Types.unify
              ~loc: prop.Parsetree.ast_loc ~self_manifest: ctx.self_manifest
              ty1 ty2);
         (* Enforce the type to be [prop]. *)
         let final_ty =
           Types.unify
             ~loc: prop.Parsetree.ast_loc
             ~self_manifest: ctx.self_manifest ty1 (Types.type_prop ()) in
         final_ty
     | Parsetree.Pr_not pr ->
         let ty = typecheck_prop ~in_proof ctx env pr in
         (* Enforce the type to be [prop]. *)
         let final_ty =
           Types.unify
             ~loc: prop.Parsetree.ast_loc
             ~self_manifest: ctx.self_manifest ty (Types.type_prop ()) in
         final_ty
     | Parsetree.Pr_expr expr ->
         (* Make the carrier abstract to prevent def-dependencies   *)
         (* with "rep" (c.f Virgile Prevosto's Phd page 52, Fig3.3) *)
         (* rule [EXPR] only when the current prop appears in a     *)
         (* theorem/property definition, not in its proof.          *)
         let ctx' =
           if in_proof then ctx else { ctx with self_manifest = None } in
         (* Expressions must be typed as [bool] OR [prop]. If *)
         (* so, then the returned  type is [prop].            *)
         let ty = typecheck_expr ctx' env expr in
         (try
           (* First try to check if it is typed bool. *)
           ignore
             (Types.unify
                ~loc: prop.Parsetree.ast_loc
                ~self_manifest: ctx'.self_manifest ty (Types.type_bool ()))
          with err ->
           (begin
            try
             (* If not bool,try to check if it is typed prop. *)
             ignore
               (Types.unify
                  ~loc: prop.Parsetree.ast_loc
                  ~self_manifest: ctx'.self_manifest ty (Types.type_prop ()))
            with _ ->
             (* If it's neither bool nor prop, then restore *)
             (* the fisrt error cause  for error report.    *)
             raise err
           end));
         Types.type_prop ()
     | Parsetree.Pr_paren pr -> typecheck_prop ~in_proof ctx env pr) in
  prop.Parsetree.ast_type <- Parsetree.ANTI_type final_ty ;
  final_ty



(* ************************************************************************* *)
(* typing_context -> Env.TypingEnv.t -> Parsetree.proof -> unit              *)
(** {b Descr} : Typechecks a [proof]. Because the type of a proof is not
              relevant in FoCaL, this function does not returns any type.
              Its only goal is to verify the type of the AST-sub-expressions
              where it is relevant and to screw this type in the [ast_type]
              field of these AST-nodes (i.e especially throug [statement]s.

    {b Rem} : Not exported outside this module.                              *)
(* ************************************************************************* *)
and typecheck_proof ctx env proof =
  (* No relevant type information to insert in the AST node. *)
  proof.Parsetree.ast_type <- Parsetree.ANTI_non_relevant ;
  match proof.Parsetree.ast_desc with
  | Parsetree.Pf_assumed -> ()
  | Parsetree.Pf_auto facts -> List.iter (typecheck_fact ctx env) facts
  | Parsetree.Pf_coq _ -> ()
  | Parsetree.Pf_node nodes -> List.iter (typecheck_node ctx env) nodes



and typecheck_node ctx env node =
  (* No relevant type information to insert in the AST node. *)
  node.Parsetree.ast_type <- Parsetree.ANTI_non_relevant ;
  match node.Parsetree.ast_desc with
  | Parsetree.PN_sub (_, statement, proof) ->
      let env' = typecheck_statement ctx env statement in
      typecheck_proof ctx env' proof
  | Parsetree.PN_qed (_, proof) -> typecheck_proof ctx env proof



(* ******************************************************************** *)
(* typing_context -> Env.TypingEnv.t -> Parsetree.statement -> unit     *)
(** {b Descr} : Typechecks a [statement]. Hypotheses are entered in the
              current environment before typechecking the optional
              [s_concl] proposition.

    {b Rem} : Not exported outside this module.                         *)
(* ******************************************************************** *)
and typecheck_statement ctx env statement =
  (* No relevant type information to insert in the AST node. *)
  statement.Parsetree.ast_type <- Parsetree.ANTI_non_relevant ;
  (* Do not fold_left otherwise the hypotheses will be *)
  (* processed in reverse order !!!                    *)
  let env' =
    List.fold_right
      (fun hyp accu_env ->
        let (name, ty) =
          (match hyp.Parsetree.ast_desc with
           | Parsetree.H_var (vname, type_expr) ->
               (vname, (typecheck_type_expr ctx accu_env type_expr))
           | Parsetree.H_hyp (vname, prop) ->
               (* Be careful, because we are not in a theorem/property *)
               (* description, but in its proof, we must not make Self *)
               (* abstract here !                                      *)
               (vname, (typecheck_prop ~in_proof: true ctx accu_env prop))
           | Parsetree.H_not (vname, expr) ->
               (vname, (typecheck_expr ctx accu_env expr))) in
        (* Record the type information in the AST node. *)
        hyp.Parsetree.ast_type <- Parsetree.ANTI_type ty ;
        (* Extend the environment for the next hypotheses and finally *)
        (* to build the complete environment that will be used to     *)
        (* typecheck the conclusion of the statement.                 *)
        let scheme = Types.generalize ty in
        Env.TypingEnv.add_value name scheme accu_env)
      statement.Parsetree.ast_desc.Parsetree.s_hyps
      env in
  (* Now, typecheck the conclusion, if some, in the extended environment. *)
  (match statement.Parsetree.ast_desc.Parsetree.s_concl with
   | None -> ()
   | Some prop ->
       (* Same remark than above pour Self being not abstract ! *)
       ignore (typecheck_prop ~in_proof: true ctx env' prop));
  (* Return the environment extended by the possible idents *)
  (* the statement binds via its hypotheses.                *)
  env'



(* ********************************************************************** *)
(* typing_context -> Env.TypingEnv.t -> Parsetree.theorem_def ->          *)
(*  Types.type_simple                                                     *)
(** {b Descr } : Typechecks a theorem definition, records its type inside
            the AST node and returns this type.
            Note that here we already are in an incremented binding
            level. Hence it is not useful to call [begin/end definition].

    {b Rem} : Not exported outside this module.                           *)
(* ********************************************************************** *)
and typecheck_theorem_def ctx env theorem_def =
  (* For the same reason that in external definition, variables present  *)
  (* in a type expression in a theorem are implicitely considered as     *)
  (* universally quantified. In effect, there no syntax to make explicit *)
  (* the quantification. Then we first create a variable mapping from    *)
  (* the type expression to avoid variable from being "unbound".         *)
  (* As stated in the header comment of the function, we already are at  *)
  (* the right binding level.                                            *)
  let vmapp =
    make_implicit_var_mapping_from_prop
      theorem_def.Parsetree.ast_desc.Parsetree.th_stmt in
  let ctx' = { ctx with tyvars_mapping = vmapp } in
  (* Ensure that Self we be abstract during the theorem's definition *)
  (* type inference by setting [~in_proof: false].                   *)
  let ty =
    typecheck_prop
      ~in_proof: false ctx' env
      theorem_def.Parsetree.ast_desc.Parsetree.th_stmt in
  (* Record the type information in the AST node. *)
  theorem_def.Parsetree.ast_type <- Parsetree.ANTI_type ty ;
  (* Now, typecheck the proof to fix types inside by side effet. *)
  typecheck_proof ctx' env theorem_def.Parsetree.ast_desc.Parsetree.th_proof ;
  (* And return the type pf the stamement as type of the theorem.*)
  ty



(* ************************************************************************* *)
(* typing_context -> Env.TypingEnv.t -> Parsetree.species_field ->           *)
(*   ((Env.TypeInformation.species_field list) * (Parsetree.proof_def list)) *)
(** {b Descr} : Infers the types of the species fields contained in the
              list. The typing environment is incrementally extended
              with the found methods and used to typecheck the next
              methods.
              The function returns a quartet whose 3 firts componente are
              suitable to be inserted in the structure of a species's type,
              and the last one is the "proof-of" fields that have been
              found among the fields. These "proof-of" must be collapsed
              with their related property to lead to a theorem before the
              normalization process starts.

    {b Rem} : Not exported outside this module.                              *)
(* ************************************************************************* *)
and typecheck_species_fields ctx env = function
  | [] -> ([(* Fields *)], ctx, [(* Proofs *)])
  | field :: rem_fields ->
      let current_species =
        (match ctx.current_species with None -> assert false | Some n -> n) in
      let (fields_tys, new_ctx, new_env, new_proofs) =
        (begin
         match field.Parsetree.ast_desc with
         | Parsetree.SF_rep rep_type_def ->
             (begin
             let rep_vname = Parsetree.Vlident "rep" in
             (* On must not defined several rep inside a species. *)
             if ctx.self_manifest <> None then
               raise (Method_multiply_defined (rep_vname, current_species));
             Types.begin_definition ();
             let ty = typecheck_rep_type_def ctx env rep_type_def in
             Types.end_definition ();
             (* Before modifying the context, just check that no "rep" *)
             (* was previously identified. If some, then fails.        *)
             if ctx.self_manifest <> None then
               raise (Rep_multiply_defined field.Parsetree.ast_loc);
             (* Extend the context with the type "rep" is equal to. Beware  *)
             (* we make a copy of the infered type in order to keep the     *)
             (* originally infered type aside any further modifications     *)
             (* that could arise while unifying anywhere "Self" with "its   *)
             (* known representation". In effect, unification in place      *)
             (* woudl establish a link by side effect from the              *)
             (* representation to the type [Types.ST_self_rep], hence       *)
             (* fooling the explicit structure of what is initially "rep".  *)
             (* This first would prevent us from being to generate code     *)
             (* finally relying on the representation of "rep". Furthermore *)
             (* because of how [Types.unify] handles unification with       *)
             (* [Types.ST_self_rep] to prevent cycles, unification of this  *)
             (* **mangled** representation would suceed with any types,     *)
             (* even those incompatible with the original **correct**       *)
             (* representation of "rep"'s type !                            *)
             let ctx' = {
               ctx with
                 self_manifest =
                   Some
                     (Types.copy_type_simple_but_variables
                        ~and_abstract: None ty) } in
             (* Record the type information in the AST node with again a *)
             (* separate copy so that Self's type that don't risk to be  *)
             (* unified somewhere, hence that will keep its effective    *)
             (* structure forever.                                       *)
             field.Parsetree.ast_type <-
               Parsetree.ANTI_type
                 (Types.copy_type_simple_but_variables
                    ~and_abstract: None ty) ;
             (* Be careful : methods are not polymorphic (c.f. Virgile    *)
             (* Prevosto's Phd section 3.3, page 24). No generalization ! *)
             let rep_scheme = Types.trivial_scheme ty in
             if Types.scheme_contains_variable_p rep_scheme then
               raise
                 (Scheme_contains_type_vars
                    (rep_vname, rep_scheme,  field.Parsetree.ast_loc));
             let field_info =
               Env.TypeInformation.SF_sig
                 (current_species, rep_vname, rep_scheme) in
             (* Record the "rep" scheme in the AST node. *)
             field.Parsetree.ast_type <- Parsetree.ANTI_scheme rep_scheme ;
             ([field_info], ctx', env, [(* Proofs *)])
             end)
         | Parsetree.SF_sig sig_def ->
             (begin
             let sig_def_descr = sig_def.Parsetree.ast_desc in
             Types.begin_definition () ;
             let ty =
               typecheck_type_expr ctx env sig_def_descr.Parsetree.sig_type in
             Types.end_definition () ;
             (* Extend the environment with this new method of Self.      *)
             (* Be careful : methods are not polymorphics (c.f. Virgile   *)
             (* Prevosto's Phd section 3.3, page 24). No generelization ! *)
             let scheme = Types.trivial_scheme ty in
             if Types.scheme_contains_variable_p scheme then
               raise
                (Scheme_contains_type_vars
                   (sig_def_descr.Parsetree.sig_name, scheme,
                    field.Parsetree.ast_loc));
             let env' =
               Env.TypingEnv.add_value
                 sig_def_descr.Parsetree.sig_name scheme env in
             let field_info =
               Env.TypeInformation.SF_sig
                 (current_species, sig_def_descr.Parsetree.sig_name, scheme) in
             (* Record the type information in the AST nodes. *)
             sig_def.Parsetree.ast_type <- Parsetree.ANTI_scheme scheme ;
             field.Parsetree.ast_type <- Parsetree.ANTI_scheme scheme ;
             ([field_info], ctx, env', [(* Proofs *)])
             end)
         | Parsetree.SF_let let_def ->
             (begin
             (* No relevant type information to record in the AST node. *)
             field.Parsetree.ast_type <- Parsetree.ANTI_non_relevant ;
             (* Don't increase level, this will be done in the let inference. *)
             (* Be careful : methods are not polymorphics (c.f. Virgile   *)
             (* Prevosto's Phd section 3.3, page 24). No generelization ! *)
             let bindings =
               typecheck_let_definition ~is_a_field: true ctx env let_def in
             (* Let's build the environment with the bindings for this let. *)
             let env' =
               List.fold_left
                 (fun accu_env (id, ty_scheme) ->
                  Env.TypingEnv.add_value id ty_scheme accu_env)
                 env bindings in
             (* We now collect the type information of these methods   *)
             (* in order to make them suitable for a "type of method". *)
             match let_def.Parsetree.ast_desc.Parsetree.ld_rec with
             | Parsetree.RF_rec ->
               (begin
                let field_infos =
                  List.map2
                    (fun (id, ty_scheme) binding ->
                     let expr =
                       binding.Parsetree.ast_desc.Parsetree.b_body in
                     let params_names =
                       List.map fst
                         binding.Parsetree.ast_desc.Parsetree.b_params in
                     (* Note that [expr] below is already typed here. *)
                     (current_species, id, params_names, ty_scheme, expr))
                    bindings
                    let_def.Parsetree.ast_desc.Parsetree.ld_bindings in
                (* Recursive, so just 1 field with several names. *)
                ([(Env.TypeInformation.SF_let_rec field_infos)], ctx, env',
                   [(* Proofs *)])
               end)
             | Parsetree.RF_no_rec ->
               (begin
               (* Not recursive, then the list should be only 1 long.  *)
               (* Anyway, if that not the case, this does not annoy.   *)
               (* So we return a list of n fields with 1 name in each. *)
               let field_infos =
                 List.map2
                   (fun (id, ty_scheme) binding ->
                    let expr =
                      binding.Parsetree.ast_desc.Parsetree.b_body in
                    let params_names =
                      List.map fst
                        binding.Parsetree.ast_desc.Parsetree.b_params in
                    (* Note that [expr] below is already typed here. *)
                    Env.TypeInformation.SF_let
                      (current_species, id, params_names, ty_scheme, expr))
                   bindings
                   let_def.Parsetree.ast_desc.Parsetree.ld_bindings in
               (field_infos, ctx, env', [(* Proofs *)])
               end)
             end)
         | Parsetree.SF_property property_def ->
             (begin
             Types.begin_definition () ;
             (* Ensure that Self we be abstract during the property's    *)
             (* definition type inference by setting [~in_proof: false]. *)
             let ty =
               typecheck_prop
                 ~in_proof: false ctx env
                 property_def.Parsetree.ast_desc.Parsetree.prd_prop in
             Types.end_definition ();
             (* Record the type information in the AST node. *)
             property_def.Parsetree.ast_type <- Parsetree.ANTI_type ty ;
             (* Extend the environment. *)
             (* Be careful : methods are not polymorphics (c.f. Virgile   *)
             (* Prevosto's Phd section 3.3, page 24). No generelization ! *)
             let scheme = Types.trivial_scheme ty in
             if Types.scheme_contains_variable_p scheme then
               raise
                 (Scheme_contains_type_vars
                    (property_def.Parsetree.ast_desc.Parsetree.prd_name,
                     scheme, field.Parsetree.ast_loc));
             let env' =
               Env.TypingEnv.add_value
                 property_def.Parsetree.ast_desc.Parsetree.prd_name
                 scheme env in
             let field_info =
               Env.TypeInformation.SF_property
                 (current_species,
                  property_def.Parsetree.ast_desc.Parsetree.prd_name,
                  scheme,
                  property_def.Parsetree.ast_desc.Parsetree.prd_prop) in
             (* Record the property's scheme in the AST node. *)
             field.Parsetree.ast_type <- Parsetree.ANTI_scheme scheme ;
             ([field_info], ctx, env', [(* Proofs *)])
             end)
         | Parsetree.SF_theorem theorem_def ->
             (begin
             Types.begin_definition () ;
             let ty = typecheck_theorem_def ctx env theorem_def in
             Types.end_definition () ;
             (* Extend the environment. *)
             (* Be careful : methods are not polymorphics (c.f. Virgile   *)
             (* Prevosto's Phd section 3.3, page 24). No generelization ! *)
             let scheme = Types.trivial_scheme ty in
             if Types.scheme_contains_variable_p scheme then
               raise
                 (Scheme_contains_type_vars
                   (theorem_def.Parsetree.ast_desc.Parsetree.th_name, scheme,
                    field.Parsetree.ast_loc)) ;
             let env' =
               Env.TypingEnv.add_value
                theorem_def.Parsetree.ast_desc.Parsetree.th_name scheme env in
             let field_info =
               Env.TypeInformation.SF_theorem
                (current_species,
                 theorem_def.Parsetree.ast_desc.Parsetree.th_name,
                 scheme,
                 theorem_def.Parsetree.ast_desc.Parsetree.th_stmt,
                 theorem_def.Parsetree.ast_desc.Parsetree.th_proof) in
             (* Record the theorem's scheme in the AST node. *)
             field.Parsetree.ast_type <- Parsetree.ANTI_scheme scheme ;
             ([field_info], ctx, env', [(* Proofs *)])
             end)
         | Parsetree.SF_proof proof_def ->
             (begin
             let proof_def_desc = proof_def.Parsetree.ast_desc in
             (* Because the type of a proof is not relevant in FoCaL,    *)
             (* the typechecking of a proof does not returns any type.   *)
             (* We record the non-relevance of the type in the AST node. *)
             proof_def.Parsetree.ast_type <- Parsetree.ANTI_non_relevant ;
             typecheck_proof ctx env proof_def_desc.Parsetree.pd_proof ;
             (* No relevant type information to record in the AST node. *)
             field.Parsetree.ast_type <- Parsetree.ANTI_non_relevant ;
             (* No extension there. *)
             ([], ctx, env, [proof_def])
             end)
        end) in
      let (rem_fields_tys, final_ctx, rem_proofs) =
        typecheck_species_fields new_ctx new_env rem_fields in
      (* Make sure that method names are not *)
      (* bound several times in the species. *)
      ensure_methods_uniquely_defined
        current_species fields_tys rem_fields_tys ;
      (* And finally the result... *)
      (fields_tys @ rem_fields_tys, final_ctx, new_proofs @ rem_proofs)
;;



(* ************************************************************************* *)
(* typing_context -> Env.TypingEnv.t -> Parsetree.expr ->                    *)
(*   (Types.type_collection * Env.TypeInformation.species_description)       *)
(** {b Descr} : Typechecks an expression in the restricted case where is it
              used as a "is" or "in" parameter effective argument. In this
              particular case, the rule [COLL-INST] expects a
              collection identifier and nothing else. For this reason, the
              identifier is looked-up in the species environment.
              Because the AST structure cannot know a priori (i.e at parsing
              stage) is the expression used as argument will be the one of a
              "is" or a "in" argument, the [expr] rule is sufficiently
              general to absorbe any possible expression, ... but is also
              too large. Hence we perfom this check afterward, during the
              typing stage.

    {b Rem} : Not exported outside this module.                              *)
(* ************************************************************************* *)
let rec typecheck_expr_as_species_parameter_argument ctx env initial_expr =
  match initial_expr.Parsetree.ast_desc with
  | Parsetree.E_self ->
      (* Should be always caught before, at scoping phase. *)
      raise
        (Scoping.Self_cant_parameterize_itself initial_expr.Parsetree.ast_loc)
  | Parsetree.E_constr (cstr_expr, []) ->
      (* We re-construct a fake ident from the constructor expression *)
      (* just to be able to lookup inside the environment.            *)
      let Parsetree.CI id_qvname = cstr_expr.Parsetree.ast_desc in
      let pseudo_ident = { cstr_expr with
        Parsetree.ast_desc = Parsetree.I_global id_qvname; } in
      let descr =
        Env.TypingEnv.find_species
          ~loc: pseudo_ident.Parsetree.ast_loc
          ~current_unit: ctx.current_unit pseudo_ident env in
      let (id_effective_module, id_name_as_string) =
        (match id_qvname with
         | Parsetree.Vname vname ->
             (ctx.current_unit, (Parsetree_utils.name_of_vname vname))
         | Parsetree.Qualified (n, vname) ->
             (n, (Parsetree_utils.name_of_vname  vname))) in
      (* Record the type in the AST nodes. *)
      let ty =
        Types.type_rep_species
          ~species_module: id_effective_module
          ~species_name: id_name_as_string in
      initial_expr.Parsetree.ast_type <- Parsetree.ANTI_type ty ;
      cstr_expr.Parsetree.ast_type <- Parsetree.ANTI_type ty ;
      (* We return the "collection type", and the collection's description. *)
      ((id_effective_module, id_name_as_string), descr)
  | Parsetree.E_paren expr ->
      let ((mod_name, species_name), desc) =
        typecheck_expr_as_species_parameter_argument ctx env expr in
      (* Record the type in the AST node. *)
      let ty =
        Types.type_rep_species
          ~species_module: mod_name ~species_name: species_name in
      initial_expr.Parsetree.ast_type <- Parsetree.ANTI_type ty ;
      ((mod_name, species_name), desc)
  | _ ->
      (* Should be always caught before, at scoping phase. *)
      raise
        (Scoping.Is_parameter_only_coll_ident initial_expr.Parsetree.ast_loc)
;;



(* ************************************************************************ *)
(* current_unit: Types.fname -> Types.type_collection ->                    *)
(*   Env.TypeInformation.species_field list ->                              *)
(*     Env.TypeInformation.species_field list                               *)
(** {b Descr} : Perform the abstraction of species methods. This implements
              the "A" function described in Virgile Prevosto's Phd, section
              3.8, page 41.

    {b Rem} : Not exported outside this module.                             *)
(* ************************************************************************ *)
let abstraction ~current_unit cname fields =
  let rec rec_abstract = function
    | [] -> []
    | h :: q ->
        let h' =
          (match h with
           | Env.TypeInformation.SF_sig (from, vname, scheme)
           | Env.TypeInformation.SF_let (from, vname, _, scheme, _) ->
               Types.begin_definition ();
               let ty = Types.specialize scheme in
               let ty' =
                 Types.copy_type_simple_but_variables
                   ~and_abstract: (Some cname) ty in
               Types.end_definition ();
               [Env.TypeInformation.SF_sig
                  (from, vname, (Types.generalize ty'))]
           | Env.TypeInformation.SF_let_rec l ->
               List.map
                 (fun (from, vname, _, scheme, _) ->
                  Types.begin_definition ();
                  let ty = Types.specialize scheme in
                  let ty' =
                    Types.copy_type_simple_but_variables
                      ~and_abstract: (Some cname) ty in
                  Types.end_definition ();
                  Env.TypeInformation.SF_sig
                    (from, vname, (Types.generalize ty')))
                 l
           | Env.TypeInformation.SF_theorem (from, vname, scheme, prop, _)
           | Env.TypeInformation.SF_property (from, vname, scheme, prop) ->
               Types.begin_definition ();
               let ty = Types.specialize scheme in
               let ty' =
                 Types.copy_type_simple_but_variables
                   ~and_abstract: (Some cname) ty in
               Types.end_definition ();
               (* We substitute Self by [cname] in the prop. *)
               let abstracted_prop =
                 SubstColl.subst_prop ~current_unit SubstColl.SCK_self
                   cname prop in
               [Env.TypeInformation.SF_property
                  (from, vname, (Types.generalize ty'), abstracted_prop)]) in
        h' @ rec_abstract q in
  (* Do the job now... *)
  rec_abstract fields
;;



(* ********************************************************************* *)
(* loc: Location.t -> typing_context ->                                  *)
(*   name_should_be_sub_spe: Types.type_collection ->                    *)
(*     Env.TypeInformation.species_field list ->                         *)
(*       name_should_be_over_spe: Types.type_collection ->               *)
(*         Env.TypeInformation.species_field list -> unit                *)
(** {b Descr} : Check that [s1] is a subspecies of [s2]. This means that
              for all (v, sc) in s2,
                ex (v, sc') in s1 and sc = sc'.
              Hence, signature [s1] is "richer" than [s2].
              The names of the 2 engaged species are provided for error
              reporting purposes.

    {b Rem} : Not exported outside this module.                          *)
(* ********************************************************************* *)
let is_sub_species_of ~loc ctx ~name_should_be_sub_spe s1
    ~name_should_be_over_spe s2 =
  let local_flat_fields fields =
    List.fold_right
      (fun field accu ->
        match field with
        | Env.TypeInformation.SF_sig (_, v, sc)
        | Env.TypeInformation.SF_let (_, v, _, sc, _) -> (v, sc) :: accu
        | Env.TypeInformation.SF_let_rec l ->
            let l' = List.map (fun (_, v, _, sc, _) -> (v, sc)) l in
            l' @ accu
        | Env.TypeInformation.SF_theorem (_, v, sc, _, _)
        | Env.TypeInformation.SF_property (_, v, sc, _) -> (v, sc) :: accu)
      fields [] in
  let flat_s1 = local_flat_fields s1 in
  let flat_s2 = local_flat_fields s2 in
  (* Check that for all (v, sc) in s2, ex (v, sc') in s1 and sc = sc'. *)
  List.iter
    (fun (v2, sc2) ->
      let found =
        List.exists
          (fun (v1, sc1) ->
            if v1 = v2 then
              (begin
               Types.begin_definition ();
               let ty1 = Types.specialize sc1 in
               let ty2 = Types.specialize sc2 in
               (begin
                (* We try to translate type errors into *)
                (* more significant error messages.     *)
                try
                  ignore
                    (Types.unify ~loc ~self_manifest: ctx.self_manifest ty1 ty2)
                with
                | Types.Conflict (ty1, ty2, _) ->
                    raise
                      (Not_subspecies_conflicting_field
                         (name_should_be_sub_spe, name_should_be_over_spe, v1,
                          ty1, ty2, loc))
                | Types.Circularity (ty1, ty2, _) ->
                    (* Mostly improbable ! *)
                    raise
                      (Not_subspecies_circular_field
                         (name_should_be_sub_spe, name_should_be_over_spe, v1,
                          ty1, ty2, loc))
                | Types.Arity_mismatch (ty_name, ar1, ar2, _) ->
                    raise
                      (Not_subspecies_arity_mismatch
                         (name_should_be_sub_spe, name_should_be_over_spe, v1,
                          ty_name, ar1, ar2,loc))
                end);
               Types.end_definition ();
               true
               end)
            else false)
          flat_s1 in
      (* Check if we found the same method name than v2 amoung the v1's . *)
      (* Note that if 2 fields with the same name were found, then either *)
      (* they can be unified, hence [found = true], or the unification    *)
      (* failed, hence we can't be here, since an exception will abort    *)
      (* the computation !                                                *)
      if not found then
        raise
          (Not_subspecies_missing_field
             (name_should_be_sub_spe, name_should_be_over_spe, v2, loc)))
      flat_s2
;;



(* *********************************************************************** *)
(* typing_context -> Env.TypingEnv.t ->                                    *)
(*   Env.TypeInformation.species_description -> Parsetree.species_param -> *)
(*     Env.TypeInformation.species_field list                              *)
(** {b Descr} : Function managing application of arguments during species
              applications in species expressions.

    {b Rem} : Not exported outside this module.                            *)
(* *********************************************************************** *)
let apply_species_arguments ctx env base_spe_descr params =
  let rec rec_apply accu_meths = function
    | [], [] -> accu_meths
    | ((f_param :: rem_f_params), (e_param :: rem_e_params)) ->
      let new_meths =
        (begin
          let (Parsetree.SP e_param_expr) = e_param.Parsetree.ast_desc in
          match f_param with
          | Env.TypeInformation.SPAR_in (f_name, f_ty) ->
             (begin
              (* First, get the argument expression's type. *)
              let expr_ty = typecheck_expr ctx env e_param_expr in
              (* The formal's collection type [f_ty] is the name of the *)
              (* collection that the effective argument is expected to  *)
              (* be a carrier of. Then one must unify the effective     *)
              (* expression's type with a "carrier" of the formal       *)
              (* collection.                                            *)
              let repr_of_formal =
                Types.type_rep_species
                  ~species_module: (fst f_ty) ~species_name: (snd f_ty) in
              let param_type_for_ast =
                Types.unify
                  ~loc: e_param.Parsetree.ast_loc
                  ~self_manifest: ctx.self_manifest repr_of_formal expr_ty in
              (* Record the type in the AST node. *)
              e_param.Parsetree.ast_type <-
                Parsetree.ANTI_type param_type_for_ast ;
              (* And now, the new methods where x <- e (in Virgile's thesis) *)
              (* i.e. here, [f_name] <- [e_param_expr].                      *)
              let substd_meths =
                List.map
                  (SubstExpr.subst_species_field
                     ~param_unit: (fst f_ty)
                     f_name e_param_expr.Parsetree.ast_desc)
                  accu_meths in
              substd_meths
             end)
          | Env.TypeInformation.SPAR_is (f_name, c1_ty, _) ->
              let c1 =
                (ctx.current_unit, Parsetree_utils.name_of_vname f_name) in
              (* Get the argument species expression signature and methods. *)
              (* Note that to be well-typed this expression must ONLY be    *)
              (* an [E_constr] (because species names are capitalized,      *)
              (* parsed as sum type constructors) that should be considered *)
              (* as a species name. C.f. Virgile Prevosto's Phd, section    *)
              (* 3.8, page 43.                                              *)
              (* Rule [COLL-INST].                                          *)
              let ((c2_mod_name, c2_species_name), expr_sp_description) =
                typecheck_expr_as_species_parameter_argument
                  ctx env e_param_expr in
              (* The c2 of Virgile's Phd. *)
              let c2 = (c2_mod_name, c2_species_name) in
              (* Record the type in the AST node. *)
              let param_type_for_ast =
                Types.type_rep_species
                  ~species_module: c2_mod_name ~species_name: c2_species_name in
              e_param.Parsetree.ast_type <-
                Parsetree.ANTI_type param_type_for_ast ;
              (* Proceed to abstraction and signature compatibility. *)
              let big_A_i1_c2 =
                abstraction ~current_unit: ctx.current_unit c2 c1_ty in
              (* Ensure that i2 <= A(i1, c2). *)
              is_sub_species_of
                ~loc: e_param.Parsetree.ast_loc ctx
                ~name_should_be_sub_spe: c2
                expr_sp_description.Env.TypeInformation.spe_sig_methods
                ~name_should_be_over_spe: c1
                big_A_i1_c2 ;
              (* And now, the new methods where c1 <- c2. *)
              let substd_meths =
                List.map
                  (SubstColl.subst_species_field
                     ~current_unit: ctx.current_unit
                     (SubstColl.SCK_coll c1) c2)
                  accu_meths in
              substd_meths
          end) in
      rec_apply new_meths (rem_f_params, rem_e_params)
    | rem_formals, _ ->
      (begin
        let rem_formals_len = List.length rem_formals in
        (* To be able to tell "... is applied to too many/to few arguments". *)
        let msg = (if rem_formals_len = 0 then "many" else "few") in
        raise (Parameterized_species_arity_mismatch msg)
       end) in
  (* Do the job now. *)
  rec_apply
    base_spe_descr.Env.TypeInformation.spe_sig_methods
    (base_spe_descr.Env.TypeInformation.spe_sig_params, params)
;;



(* **************************************************************** *)
(* typing_context -> Env.TypingEnv.t -> Parsetree.species_expr ->   *)
(*   Env.TypeInformation.species_field list                         *)
(** {b Descr} : Typechecks a species expression, record its type in
              the AST node and return the list of its methods names
              type schemes and possible bodies (the list of fields
              in fact).

    {b Rem} :Not exported outside this module.                      *)
(* **************************************************************** *)
let typecheck_species_expr ctx env species_expr =
  let species_expr_desc = species_expr.Parsetree.ast_desc in
  (* Recover the information about the species. *)
  let species_species_description =
    Env.TypingEnv.find_species
      ~loc: species_expr.Parsetree.ast_loc
      ~current_unit: ctx.current_unit species_expr_desc.Parsetree.se_name env in
  (* Create the type of this species. *)
  let (species_module, species_name) =
    (match species_expr_desc.Parsetree.se_name.Parsetree.ast_desc with
     | Parsetree.I_local vname
     | Parsetree.I_global (Parsetree.Vname vname) ->
         (ctx.current_unit, (Parsetree_utils.name_of_vname vname))
     | Parsetree.I_global (Parsetree.Qualified (fname, vname)) ->
         (fname, (Parsetree_utils.name_of_vname vname))) in
  let species_carrier_type =
    Types.type_rep_species ~species_module ~species_name in
  (* Record the type in the AST nodes. *)
  species_expr.Parsetree.ast_type <- Parsetree.ANTI_type species_carrier_type ;
  species_expr_desc.Parsetree.se_name.Parsetree.ast_type <-
    Parsetree.ANTI_type species_carrier_type ;
  (* Now, create the "species type" (a somewhat of signature). *)
  let species_methods =
    apply_species_arguments ctx env
      species_species_description
      species_expr_desc.Parsetree.se_params in
  (* Record the type in the AST node. *)
  species_expr.Parsetree.ast_type <- Parsetree.ANTI_type species_carrier_type ;
  species_methods
;;



(* *********************************************************************** *)
(* typing_context -> Env.TypingEnv.t ->                                    *)
(*   (Parsetree.vname * Parsetree.species_param_type) list ->              *)
(*     (Env.TypingEnv.t * Env.TypeInformation.species_param list *         *)
(*      Types.type_species)                                                *)
(** {b Descr} : Performs the typechecking of a species definition
              parameters.
              It build the species type of the species owning these
              parameters and return it.
              It also build the list of [Env.TypeInformation.species_param]
              that will appear in the hosting species [spe_sig_params]
              field.
              It also extend the environment with the species
              induced by the parameters and the carrier types of
              these species induced by the parameters.

    {b Rem} : Not exported outside this module.                            *)
(* *********************************************************************** *)
let typecheck_species_def_params ctx env species_params =
  let rec rec_typecheck_params accu_env = function
    | [] -> (accu_env, [])
    | (param_vname, param_kind) :: rem ->
        (begin
        let param_name_as_string = Parsetree_utils.name_of_vname param_vname in
        match param_kind.Parsetree.ast_desc with
         | Parsetree.SPT_in ident ->
             (begin
             (* Recover the module and the species name that the parameter *)
             (* must be of.                                                *)
             let (param_sp_module, param_sp_name) =
               (match ident.Parsetree.ast_desc with
                | Parsetree.I_local vname
                | Parsetree.I_global (Parsetree.Vname vname) ->
                    (ctx.current_unit, (Parsetree_utils.name_of_vname vname))
                | Parsetree.I_global (Parsetree.Qualified (fname, vname)) ->
                    (fname, (Parsetree_utils.name_of_vname vname))) in
             (* Just check that the species exists to avoid raising an  *)
             (* error at application-time if the species doesn't exist. *)
             ignore
               (Env.TypingEnv.find_species
                  ~loc: ident.Parsetree.ast_loc ~current_unit: ctx.current_unit
                  ident accu_env) ;
             (* Create the carrier type of the parameter and extend the *)
             (* current environment with this parameter as a value of   *)
             (* the carrier type.                                       *)
             Types.begin_definition () ;
             let param_carrier_ty =
               Types.type_rep_species ~species_module: param_sp_module
                 ~species_name: param_sp_name in
             Types.end_definition () ;
             (* Record the type of the parameter in the AST nodes. *)
             param_kind.Parsetree.ast_type <-
               Parsetree.ANTI_type param_carrier_ty ;
             ident.Parsetree.ast_type <- Parsetree.ANTI_type param_carrier_ty ;
             (* Extend the environment with the parameter bound to its type. *)
             let accu_env' =
               Env.TypingEnv.add_value
                 param_vname (Types.generalize param_carrier_ty) accu_env in
             (* And now, build the species type of the application. *)
             let (accu_env'', rem_spe_params) =
               rec_typecheck_params accu_env' rem in
             let current_spe_param =
               Env.TypeInformation.SPAR_in
                 (param_vname, (param_sp_module, param_sp_name)) in
             (* Finally, we return the fully extended environment and *)
             (* the type of the species application we just built.    *)
             (accu_env'', (current_spe_param:: rem_spe_params))
             end)
         | Parsetree.SPT_is species_expr ->
             (begin
             (* First, typecheck the species expression.          *)
             let species_expr_fields =
               typecheck_species_expr ctx accu_env species_expr in
             (* Create the [species_description] of the parameter *)
             (* and extend the current environment. Because the   *)
             (* obtained species is not a declaration, it cannot  *)
             (* have parameters or inheritance.                   *)
             (* This leads to a somewhat of "local" species, and  *)
             (* we will bind it in the species environment under  *)
             (* an internal name to be able to denote it in the   *)
             (* type of the application.                          *)
             (* This internal name is the name of the parameter.  *)
             let abstracted_methods =
               abstraction
                 ~current_unit: ctx.current_unit
                 (ctx.current_unit, param_name_as_string) species_expr_fields in
             let param_description = {
               Env.TypeInformation.spe_is_collection = false ;
               Env.TypeInformation.spe_is_closed = false ;
               Env.TypeInformation.spe_sig_params = [] ;
               Env.TypeInformation.spe_sig_methods = abstracted_methods } in
             let accu_env' =
               Env.TypingEnv.add_species
                 ~loc: species_expr.Parsetree.ast_loc
                 param_vname param_description accu_env in
             (* Create the carrier type of the parameter *)
             (* and extend the current environment.      *)
             Types.begin_definition () ;
             let param_carrier_ty =
               Types.type_rep_species ~species_module: ctx.current_unit
                 ~species_name: param_name_as_string in
             Types.end_definition () ;
             (* Record the type of the parameter in the AST node. *)
             param_kind.Parsetree.ast_type <-
               Parsetree.ANTI_type param_carrier_ty ;
             (* Create the type description of the carrier the parameter is. *)
             let param_carrier_ty_description = {
               Env.TypeInformation.type_kind = Env.TypeInformation.TK_abstract ;
               Env.TypeInformation.type_identity =
               Types.generalize param_carrier_ty ;
               (* No param because the species is fully applied. *)
               Env.TypeInformation.type_params = [];
               Env.TypeInformation.type_arity = 0 } in
             let accu_env'' =
               Env.TypingEnv.add_type
                 ~loc: species_expr.Parsetree.ast_loc
                 param_vname param_carrier_ty_description accu_env' in
             (* And now, build the species type of the application. *)
             let (accu_env''', rem_spe_params) =
               rec_typecheck_params accu_env'' rem in
             (* We keep the [species_expr]'s in the [SPAR_is] structure *)
             (* because it will be needed for Coq code generation.      *)
             let current_spe_param =
               Env.TypeInformation.SPAR_is
                 (param_vname, species_expr_fields, species_expr) in
             (* Finally, we return the fully extended environment and *)
             (* the type of the species application we just built.    *)
             (accu_env''', (current_spe_param :: rem_spe_params))
             end)
        end) in
  (* And now do the job... *)
  rec_typecheck_params env species_params
;;



(* ********************************************************************** *)
(* loc: Location.t -> typing_context -> Env.TypingEnv.t ->                *)
(* Parsetree.species_expr list ->                                         *)
(*   (Env.TypeInformation.species_field list *                            *)
(*    Env.TypingEnv.t * typing_context)                                   *)
(** {b Descr} : Extends an environment as value bindings with the methods
              of the inherited species provided in argument. Methods are
              added in the same order than their hosting species comes
              in the inheritance list. This means that the methods of the
              first inherited species will be deeper in the resulting
              environment.
              Extends the typing_context if among the inherited methods
              "rep" is found. In this case, this means that the carrier
              is manifest and changes the typing_context with its
              representation.

    {b Rem} :Not exported outside this module.                            *)
(* ********************************************************************** *)
let extend_env_with_inherits ~loc ctx env spe_exprs =
  let rec rec_extend current_ctx current_env accu_found_methods = function
    | [] -> (accu_found_methods, current_env, current_ctx)
    | inh :: rem_inhs ->
      (* First typecheck the species expression in the initial   *)
      (* (non extended) and recover its methods names and types. *)
      let inh_species_methods = typecheck_species_expr current_ctx env inh in
      let (env', current_ctx')  =
        List.fold_left
          (fun (accu_env, accu_ctx) field ->
            match field with
             | Env.TypeInformation.SF_sig (_, meth_name, meth_scheme)
             | Env.TypeInformation.SF_let (_, meth_name, _, meth_scheme, _) ->
               let e =
                 Env.TypingEnv.add_value meth_name meth_scheme accu_env in
               (* Now check if we inherited a [rep]. *)
               let m_name_as_str =
                 Parsetree_utils.name_of_vname meth_name in
               let manifest =
                 (if m_name_as_str = "rep" then
                   (begin
                    (* Before modifying the context, just check that no *)
                    (* "rep" was previously identified. If some, then   *)
                    (* fail.                                            *)
                    if accu_ctx.self_manifest <> None
                    then raise (Rep_multiply_defined loc);
                    Some (Types.specialize meth_scheme)
                   end)
                  else accu_ctx.self_manifest) in (* Else, keep unchanged. *)
               let c = { accu_ctx with self_manifest = manifest } in
               (e, c)
             | Env.TypeInformation.SF_let_rec l ->
               let e =
                 List.fold_left
                   (fun internal_accu_env
                        (_, meth_name, _, meth_scheme, _) ->
                    Env.TypingEnv.add_value
                      meth_name meth_scheme internal_accu_env)
                   accu_env
                   l in
               (e, accu_ctx)
             | Env.TypeInformation.SF_theorem  (_, theo_name, t_sch, _, _) ->
               let e =
                 Env.TypingEnv.add_value theo_name t_sch accu_env in
               (e, accu_ctx)
             | Env.TypeInformation.SF_property (_, prop_name, prop_sch, _) ->
               let e =
                 Env.TypingEnv.add_value prop_name prop_sch accu_env in
                 (e, accu_ctx))
          (current_env, current_ctx)
          inh_species_methods in
      let new_accu_found_methods = accu_found_methods @ inh_species_methods in
      (* Go on with the next inherited species. *)
      rec_extend current_ctx' env' new_accu_found_methods rem_inhs in
  (* ****************** *)
  (* Now, let's work... *)
  rec_extend ctx env [] spe_exprs
;;



(* ************************************************************************ *)
(* Parsetree.proof_def_desc -> current_species:Parsetree.qualified_vname -> *)
(*   Env.TypeInformation.species_field list ->                              *)
(*     (Env.TypeInformation.species_field list * bool)                      *)


(* {b Descr} : Searches in the list the first SF_property field whose
             name is equal to the [proof_of]'s name, then convert
             this property field into a theorem fields by adding the
             [pd_proof] field of the [proof_of].
             Then return the initial [fields] list with this field
             transformed inside and a boolean telling if a change
             finally occured.
             This process is used to make Parsetree.SF_proof diseaper,
             merging their proof in the related property definition in
             order to create an equivalent theorem instead.

   {b Rem} : Not exported outside this module.                              *)
(* ************************************************************************ *)
let collapse_proof proof_of ~current_species fields =
  let name_of_proof_of = proof_of.Parsetree.pd_name in
  let rec rec_find = function
    | [] -> ([], false)
    | field :: rem ->
      (begin
        match field with
        | Env.TypeInformation.SF_sig (_, _, _)
        | Env.TypeInformation.SF_let (_, _, _, _, _)
        | Env.TypeInformation.SF_let_rec _
        | Env.TypeInformation.SF_theorem _ ->
          let (collapsed_rem, was_collapsed) = rec_find rem in
          (field :: collapsed_rem, was_collapsed)
        | Env.TypeInformation.SF_property (_, name, sch, prop) ->
          (begin
            if name_of_proof_of = name then
              (begin
                (* We found the property related to the proof. *)
                (* Change this property into a theorem.        *)
                let new_field =
                  Env.TypeInformation.SF_theorem
                    (current_species, name, sch, prop,
                     proof_of.Parsetree.pd_proof) in
                if Configuration.get_verbose () then
                  Format.eprintf
                    "Merging property '%a' and proof into theorem.@."
                    Sourcify.pp_vname name;
                (* Stop the search now. Say that a change actually occured. *)
                (new_field :: rem, true)
              end)
            else
              (begin
                (* Like the cas where the field was not a [SF_property]. *)
                let (collapsed_rem, was_collapsed) = rec_find rem in
                ((field :: collapsed_rem), was_collapsed)
               end)
           end)
       end) in
  rec_find fields
;;



(* ************************************************************************ *)
(* current_species: Parsetree.qualified_vname -> Parsetree.proof_def ->     *)
(*  Env.TypeInformation.species_field list ->                               *)
(*    Env.TypeInformation.species_field list ->                             *)
(*      (Env.TypeInformation.species_field list *                           *)
(*       Env.TypeInformation.species_field list)                            *)
(* {b Descr} : Tries to find among [methods], property fields whose proofs
             are separately given in the list of proofs [found_proofs_of].
             Each time the search succeeds, the property and the related
             proof are merge in a new theorem field, hence discarding the
             property fiels.
             Because this process is performed before the normalization
             pass, we still require to have 2 separate lists of methods:
              - the inherited ones,
              - those defined at the current inheritance level.
             For this reason, the search will be done first on the methods
             defined at the current inheritance level (in order to find
             the "most recent") and only if the search failed, we will try
             it again on the inherited methods?

   {b Rem} : BE CAREFUL, such a merge now require a re-ordering of the
             final fields. In effect, by moving the proof_of field when
             merging it as a [SF_theorem] located where the initial
             [SF_property] field was, if the proof (that was originally
             "later") uses stuff defined between the [SF_property] and
             the original location of the proof, then this stuff will
             now appear "after" the proof itself. And this is not
             well-formed.
             Not exported outside this module.                              *)
(* ************************************************************************ *)
let collapse_proofs_of ~current_species found_proofs_of
      inherited_methods_infos methods_info =
  (* We must first reverse the lists of methods so that the collapse *)
  (* procedure will find first the most recent methods.             *)
  let revd_inherited_methods_infos = List.rev inherited_methods_infos in
  let revd_methods_info = List.rev methods_info in
  let (revd_collapsed_inherited_methods, revd_collapsed_current_methods) =
    List.fold_left
      (fun (accu_inherited, accu_current) found_proof_of ->
        (* First, try on the "most recent" methods, i.e. the current *)
        (* inheritance level's ones.                                 *)
        let (collapsed_current, was_collapsed) =
          collapse_proof
            ~current_species found_proof_of.Parsetree.ast_desc accu_current in
        if was_collapsed then (accu_inherited, collapsed_current)
        else
          (begin
            (* No collapse in the current level's       *)
            (* methods, then try on the inherited ones. *)
            let (collapsed_inherited, was_collapsed) =
              collapse_proof
                ~current_species found_proof_of.Parsetree.ast_desc
                accu_inherited in
            if was_collapsed then (collapsed_inherited, accu_current)
            else (accu_inherited, accu_current)      (* No collapse at all ! *)
           end))
      (revd_inherited_methods_infos, revd_methods_info)
      found_proofs_of in
  (* And then, reverse again the result to get *)
  (* again the initial and correct order.      *)
  (List.rev revd_collapsed_inherited_methods,
   List.rev revd_collapsed_current_methods)
;;



(* ********************************************************************** *)
(* Parsetree.vname -> Env.TypeInformation.species_field list ->           *)
(*   (Env.TypeInformation.species_field *                                 *)
(*    (Env.TypeInformation.species_field list))                           *)
(** {b Descr} : Among the fields list [fields], find the one binding the
              name [name]. Return both the found field and the list minus
              this found field.

    {b Rem} : Not exported outside this module.                           *)
(* ********************************************************************** *)
let extract_field_from_list_by_name name fields =
  let rec rec_extract = function
    | [] -> assert false      (* By construction, the field MUST exist. *)
    | field :: rem ->
      (begin
        let found =
          (match field with
           | Env.TypeInformation.SF_sig (_, n, _)
           | Env.TypeInformation.SF_let (_, n, _, _, _)
           | Env.TypeInformation.SF_theorem (_, n, _, _, _)
           | Env.TypeInformation.SF_property (_, n, _, _) -> name = n
           | Env.TypeInformation.SF_let_rec l ->
             List.exists (fun (_, n, _, _, _) -> name = n) l) in
        if found then (field, rem) else
          let (found_field, tail) = rec_extract rem in
          (found_field, field :: tail)
       end) in
  rec_extract fields
;;



(* ********************************************************************* *)
(* Parsetree.vname list -> Parsetree.vname list                          *)
(** {b Descr} : Looks for "rep" in the names list [l]. If found, then
              remove it from its place and put it again but as the first
              element of the list.

    {b Rem} : Implicitely assumes that "rep" exists at most once in the
            list [l] (no doubles).
            Not exported outside this module.                            *)
(* ********************************************************************* *)
let ensure_rep_in_first l =
  let rec rec_search = function
    | [] -> ([], false)
    | h :: q ->
        (* If it's "rep", then stop and return the list without "rep". *)
        (* Of course, by stopping search we assume that "rep" is at    *)
        (* most once in the list (no doubles).                         *)
        if h = Parsetree.Vlident "rep" then (q, true) else
          let (filtered_q, found) = rec_search q in
          (h :: filtered_q, found) in
  (* Go... *)
  let (new_l, was_found) = rec_search l in
  (* If "rep" was found, then it was also removed, then re-add it in front. *)
  if was_found then (Parsetree.Vlident "rep") :: new_l else new_l
;;



(* ******************************************************************** *)
(* Parsetree.vname list ->  Env.TypeInformation.species_field list ->   *)
(*   Env.TypeInformation.species_field list                             *)
(** {b Descr} : Effectively reorganize the fields contained in the list
              [fields] to make them appear in the order provided by the
              list of names [order].
              For [Let_rec] fields, their order of apparition is given
              by the order of the first name (rec bound) appearing in
              the order list.
              ATTENTION : The only exception is "rep" which if present
              is always put at the beginning of the list !

    {b Rem} : Not exported outside this module.                         *)
(* ******************************************************************** *)
let order_fields_according_to order fields =
  let rec rec_reorder rec_order rec_fields =
    match rec_order, rec_fields with
    | [], [] -> []
    | [], _ | _, [] ->
      (* If there are spurious fields or names then *)
      (* it's because we went wrong somewhere ! *)
      assert false
    | name :: _, _ ->
      (* We first find the field hosting [name]. This field will be *)
      (* inserted here in the result list. We then must remove from *)
      (* the order list, all the name rec-bound with [name]. Then   *)
      (* we continue with this new order and the fields list from   *)
      (* which we remove the found field. This way, the fields list *)
      (* in which we search will be smaller and smaller (cool for   *)
      (* efficiency), and will finish to be empty.                  *)
      let (related_field, new_rec_fields) =
        extract_field_from_list_by_name name rec_fields in
      let names_bound =
        Dep_analysis.ordered_names_list_of_fields [related_field] in
      (* So, remove from the order the rec-bound names... *)
      let new_rec_order =
        List.filter (fun n -> not (List.mem n names_bound)) rec_order in
      related_field :: (rec_reorder new_rec_order new_rec_fields) in
  (* Now do the job. First, if "rep" is in the order, then *)
  (* ensure that it is the first in the list.              *)
  let order_with_rep_in_front = ensure_rep_in_first order in
  rec_reorder order_with_rep_in_front fields
;;



(* ********************************************************************* *)
(* loc:Location.t -> typing_context -> Parsetree.vname ->                *)
(*   Types.type_scheme ->                                                *)
(*     (Types.species_name * Parsetree.vname * Types.type_scheme *       *)
(*      Parsetree.expr) list ->                                          *)
(*       Env.TypeInformation.species_field                               *)
(** {b Descr} : Implements the "fusion" algorithm (c.f [fields_fusion])
              in the particular case of fusionning 1 field Sig and 1
              field Let_rec.

    {b Rem} : Not exported outside this module.                          *)
(* ********************************************************************* *)
let fusion_fields_let_rec_sig ~loc ctx sig_name sig_scheme rec_meths =
  let rec_meths' =
    List.map
      (fun ((from, n, params_names, sc, body) as rec_meth) ->
        if n = sig_name then
          begin
           Types.begin_definition ();
           let sig_ty = Types.specialize sig_scheme in
           let ty = Types.specialize sc in
           (* Recover the type where Self is prefered. *)
           let ty' =
             Types.unify ~loc ~self_manifest: ctx.self_manifest sig_ty ty in
           Types.end_definition ();
           (from, n, params_names, (Types.generalize ty'), body)
          end
        else rec_meth)
      rec_meths in
  Env.TypeInformation.SF_let_rec rec_meths'
;;



(* ******************************************************************** *)
(* 'a -> ('b * 'a * 'c * 'd * 'e) list ->                               *)
(*   ('b * 'a * 'c * 'd * 'e) * ('b * 'a * 'c * 'd * 'e) list           *)
(* {b Descr} : Searches in the list the first element whose first
             component is equal to [name], then returns it and the list
             minus this element.
             If the searched name is not found in the list, then the
             exception [Not_found] is raised.

   {b Rem} : Not exported outside this module.                          *)
(* ******************************************************************** *)
let find_and_remain name meths =
  let rec rec_find = function
    | [] -> raise Not_found
    | ((_, n, _, _, _) as meth) :: rem ->
        if name = n then (meth, rem) else
          let (found, tail) = rec_find rem in
          (found, (meth :: tail)) in
  rec_find meths
;;



(* ******************************************************************** *)
(* loc: Location.t -> typing_context ->                                 *)
(*   (Types.species_name * Parsetree.vname * Types.type_scheme *        *)
(*    Parsetree.expr) list ->                                           *)
(*     (Types.species_name *  Parsetree.vname * Types.type_scheme *     *)
(*      Parsetree.expr) list ->                                         *)
(*       Env.TypeInformation.species_field                              *)
(** {b Descr} : Implements the "fusion" algorithm (c.f [fields_fusion])
              in the particular case of fusionning 2 fields Let_rec.

    {b Rem} : Not exported outside this module.                         *)
(* ******************************************************************** *)
let fusion_fields_let_rec_let_rec ~loc ctx rec_meths1 rec_meths2 =
  let rec rec_fusion l1 l2 =
    match l1 with
    | [] -> l2
    | ((_, n1, _, sc1, _) as meth) :: rem1 ->
      let (fused_meth, new_l2) =
        (try
          let (m2, rem_of_l2) = find_and_remain n1 l2 in
          let (_, _, _, sc2, _) = m2 in
          let ty1 = Types.specialize sc1 in
          let ty2 = Types.specialize sc2 in
          (* Ensure that the 2 versions of the method are type-compatible. *)
          ignore
            (Types.unify ~loc ~self_manifest: ctx.self_manifest ty1 ty2);
          (* And return the seconde one (late binding). *)
          (m2, rem_of_l2)
         with Not_found ->
          (* The method doesn't belog to l2, then keep this one. *)
          (meth, l2)) in
      (* Now make the fusion of the remaining of l1 and the remaining *)
      (* of l2 (this las one being possibly l2 if the search failed). *)
      let rem_fused_methods = rec_fusion rem1 new_l2 in
      fused_meth :: rem_fused_methods in
  (* Go... *)
  Env.TypeInformation.SF_let_rec (rec_fusion rec_meths1 rec_meths2)
;;



(* ************************************************************************* *)
(* loc: Location.t -> typing_context -> Env.TypeInformation.species_field -> *)
(*   Env.TypeInformation.species_field -> Env.TypeInformation.species_field  *)
(** {b Descr} : Implements the "fusion" algorithm described in Virgile
              Prevosto's Phd, Section 3.6, page 35.
              This basically ensure that 2 fields with at leat 1 common
              name are type-compatible and select the new field information
              that summarizes these 2 original fields (implementing the late
              binding feature by the way).

    {b Rem} : Not exported outside this module.                              *)
(* ************************************************************************* *)
let fields_fusion ~loc ctx phi1 phi2 =
  match phi1, phi2 with
   (* *** *)
   | (Env.TypeInformation.SF_sig (_, n1, sc1),
      Env.TypeInformation.SF_sig (from2, n2, sc2)) when n1 = n2 ->
        (* sig / sig. *)
        Types.begin_definition ();
        let ty1 = Types.specialize sc1 in
        let ty2 = Types.specialize sc2 in
        let ty = Types.unify ~loc ~self_manifest: ctx.self_manifest ty1 ty2 in
        Types.end_definition ();
        Env.TypeInformation.SF_sig (from2, n2, (Types.generalize ty))
   | (Env.TypeInformation.SF_sig (_, n1, sc1),
      Env.TypeInformation.SF_let (from2, n2, pars2, sc2, body)) when n1 = n2 ->
        (* sig / let. *)
        Types.begin_definition ();
        let ty1 = Types.specialize sc1 in
        let ty2 = Types.specialize sc2 in
        let ty = Types.unify ~loc ~self_manifest: ctx.self_manifest ty1 ty2 in
        Types.end_definition ();
        Env.TypeInformation.SF_let
          (from2, n2, pars2, (Types.generalize ty), body)
   | (Env.TypeInformation.SF_sig (_, n1, sc1),
      Env.TypeInformation.SF_let_rec rec_meths) ->
        (* sig / let rec. *)
        fusion_fields_let_rec_sig ~loc ctx n1 sc1 rec_meths
   (* *** *)
   | (Env.TypeInformation.SF_let (from1, n1, pars1, sc1, body),
      Env.TypeInformation.SF_sig (_, n2, sc2)) when n1 = n2 ->
        (* let / sig. *)
        Types.begin_definition ();
        let ty1 = Types.specialize sc1 in
        let ty2 = Types.specialize sc2 in
        let ty = Types.unify ~loc ~self_manifest: ctx.self_manifest ty1 ty2 in
        Types.end_definition ();
        Env.TypeInformation.SF_let
          (from1, n1, pars1, (Types.generalize ty), body)
   | (Env.TypeInformation.SF_let (_, n1, _, sc1, _),
      Env.TypeInformation.SF_let (from2, n2, pars2, sc2, body)) when n1 = n2 ->
        (* let / let. *)
        (* Late binding : keep the second body ! *)
        Types.begin_definition ();
        let ty1 = Types.specialize sc1 in
        let ty2 = Types.specialize sc2 in
        let ty = Types.unify ~loc ~self_manifest: ctx.self_manifest ty1 ty2 in
        Types.end_definition ();
        Env.TypeInformation.SF_let
          (from2, n2, pars2, (Types.generalize ty), body)
   | (Env.TypeInformation.SF_let (_, _, _, _, _),
      Env.TypeInformation.SF_let_rec _) ->
        failwith "fields_fusion let / let rec"
   (* *** *)
   | (Env.TypeInformation.SF_let_rec rec_meths,
      Env.TypeInformation.SF_sig (_, n2, sc2)) ->
        (* let rec / sig. *)
        (* Symetric case than for sig / let_rec. *)
        fusion_fields_let_rec_sig ~loc ctx n2 sc2 rec_meths
   | (Env.TypeInformation.SF_let_rec _,
      Env.TypeInformation.SF_let (_, _, _, _, _)) ->
        failwith "fields_fusion let rec / let"
   | (Env.TypeInformation.SF_let_rec rec_meths1,
      Env.TypeInformation.SF_let_rec rec_meths2) ->
        fusion_fields_let_rec_let_rec ~loc ctx rec_meths1 rec_meths2
   | ((Env.TypeInformation.SF_property (_, n1, sc1, prop1)),
      (Env.TypeInformation.SF_property (_, n2, sc2, prop2)))
   | ((Env.TypeInformation.SF_property (_, n1, sc1, prop1)),
      (Env.TypeInformation.SF_theorem (_, n2, sc2, prop2, _)))
   | ((Env.TypeInformation.SF_theorem (_, n1, sc1, prop1, _)),
      (Env.TypeInformation.SF_theorem (_, n2, sc2, prop2, _))) ->
        (* First, ensure that the names are the same. *)
        if n1 = n2 then
          (begin
            (* Now ensure that types are the same. *)
            let ty1 = Types.specialize sc1 in
            let ty2 = Types.specialize sc2 in
            (try
              ignore
                (Types.unify ~loc ~self_manifest: ctx.self_manifest ty1 ty2)
             with _ -> assert false);
            (* Finally, ensure that the propositions are the same. *)
            if Ast_equal.prop prop1 prop2 then
              (* Return the theorem in case of property / theorem and  *)
              (* return the last theorem in case of theorem  /theorem. *)
              phi2
            else assert false
           end)
        else assert false
   | ((Env.TypeInformation.SF_theorem (_, n1, sc1, prop1, _)),
      (Env.TypeInformation.SF_property (_, n2, sc2, prop2))) ->
        (* First, ensure that the names are the same. *)
        if n1 = n2 then
          (begin
            (* Now ensure that types are the same. *)
            let ty1 = Types.specialize sc1 in
            let ty2 = Types.specialize sc2 in
            (try
              ignore
                (Types.unify ~loc ~self_manifest: ctx.self_manifest ty1 ty2)
             with _ -> assert false);
            (* Finally, ensure that the propositions are the same. *)
            if Ast_equal.prop prop1 prop2
            then phi1 (* Return the theorem. *)
            else assert false
          end)
        else assert false
   | _ -> assert false (* From Virgile's thesis Lemma 8 p 37 *)
;;



(* ************************************************************************ *)
(* Env.TypeInformation.species_field ->                                     *)
(*   Env.TypeInformation.species_field list ->                              *)
(*     (Env.TypeInformation.species_field option *                          *)
(*      Env.TypeInformation.species_field list *                            *)
(*      Env.TypeInformation.species_field list)                             *)
(** {b Descr} : Searches in the list of fields [fields] the oldest field
              sharing a name in common with the field [phi]. Then it
              returns this field of [fields] and the list [fields] itself
              minus the found field splitted in two parts :
               - the head formed by the elements before the found field,
               - the tail formed by the elements after the found field.
              This function intends to serves in the normalization
              algorithm described in Virgile Prevosto's Phd, Section 3.7.1,
              page 36. It addresses the problem of "finding i_0 the
              smallest index such as N(phi) inter N(psi_0) <> empty".

    {b Rem} : Not exported outside this module.                             *)
(* ************************************************************************ *)
let oldest_inter_n_field_n_fields phi fields =
  let flat_phi_names =
    (match phi with
     | Env.TypeInformation.SF_sig (_, v, _)
     | Env.TypeInformation.SF_let (_, v, _, _, _) -> [v]
     | Env.TypeInformation.SF_let_rec l -> List.map (fun (_, v, _, _, _) -> v) l
     | Env.TypeInformation.SF_theorem (_, v, _, _, _) -> [v]
     | Env.TypeInformation.SF_property (_, v, _, _) -> [v]) in
  (* We will now check for an intersection between the list of names *)
  (* from phi and the names of one field of the argument [fields].   *)
  let rec rec_hunt = function
    | [] -> (None, [], [])
    | f :: rem_f ->
      (begin
        match f with
        | Env.TypeInformation.SF_sig (_, v, _)
        | Env.TypeInformation.SF_let (_, v, _, _, _)
        | Env.TypeInformation.SF_theorem (_, v, _, _, _)
        | Env.TypeInformation.SF_property (_, v, _, _) ->
            if List.mem v flat_phi_names then ((Some f), [], rem_f)
            else
              let (found, head_list, rem_list) = rec_hunt rem_f in
              (* Not found in [f], then add it in the head part. *)
              (found, (f :: head_list), rem_list)
        | Env.TypeInformation.SF_let_rec l ->
            let names_in_l = List.map (fun (_, v, _, _, _) -> v) l in
            if Handy.list_intersect_p flat_phi_names names_in_l then
              ((Some f), [], rem_f)
            else
              let (found, head_list, rem_list) = rec_hunt rem_f in
              (* Not found in [f], then add it in the head part. *)
              (found, (f :: head_list), rem_list)
      end) in
  rec_hunt fields
;;



(* **************************************************************** *)
(** {b Descr} : Implements the normalization algorithm described in
              Virgile Prevosto's Phd, Section 3.7.1, page 36 plus
              its extention to properties and theorems in Section
              3.9.7, page 57.

    {b Rem}: Not exported outside this module.                      *)
(* **************************************************************** *)
let normalize_species ~loc ctx methods_info inherited_methods_infos =
  let w1 = ref (inherited_methods_infos @ methods_info) in
  let w2 = ref ([] : Env.TypeInformation.species_field list) in
  let continue = ref true in
  while !continue do
    match !w1 with
    | [] -> continue := false
    | phi :: bigX ->
      (begin
        match oldest_inter_n_field_n_fields phi !w2 with
        | (None, _, _) ->
           w1 := bigX;
           w2 := !w2 @ [phi]
        | (Some psi_i0, head_sniped_w2, tail_sniped_w2) ->
           (* Extract the names forming the erasing context. *)
           let psi_i0_names =
             Dep_analysis.ordered_names_list_of_fields [psi_i0] in
           w1 :=  (fields_fusion ~loc ctx psi_i0 phi) :: bigX;
           (* Rather apply the formula Section of Section 3.9.7, page 57. *)
           (* Hence we erase in the tail of the list, i.e. in fields      *)
           (* found after [psi_i0].                                       *)
           let current_species =
             (match ctx.current_species with
              | None -> assert false
              | Some sp_name -> sp_name) in
           let erased_tail =
             Dep_analysis.erase_fields_in_context
               ~current_species psi_i0_names tail_sniped_w2 in
           w2 := head_sniped_w2 @ erased_tail
        end)
  done;
  !w2
;;



(* ******************************************************************* *)
(* typing_context -> Env.TypeInformation.species_field list -> unit    *)
(** {b Descr} : Verifies that a species subject to become a collection
              is really fully defined. This means that this species
              must not contain any "declared" fields (i.e. SF_sig)
              except for "repr" who must be declared (of course, its
              declaration is also its definition !).

    {b Rem} : Not exported outside this module.                        *)
(* ******************************************************************* *)
let ensure_collection_completely_defined ctx fields =
  (* Let just make a reference for checking the presence pf "rep" instead *)
  (* of passing a boolean flag. This way, the function keeps terminal.    *)
  let rep_found = ref false in
  let rec rec_ensure = function
    | [] -> ()
    | field :: rem_fields ->
      (begin
        match field with
        | Env.TypeInformation.SF_sig (_, vname, _) ->
          if vname = (Parsetree.Vlident "rep") then rep_found := true
          else
           (begin
             match ctx.current_species with
             | None -> assert false
             | Some curr_spec ->
               raise (Collection_not_fully_defined (curr_spec, vname))
            end)
        | Env.TypeInformation.SF_let (_, _, _, _, _) -> ()
        | Env.TypeInformation.SF_let_rec _ -> ()
        | Env.TypeInformation.SF_theorem (_, _, _, _, _) -> ()
        | Env.TypeInformation.SF_property (_, vname, _, _) ->
          (begin
            (* A property does not have proof. So, it is not fully defined. *)
            match ctx.current_species with
            | None -> assert false
            | Some curr_spec ->
              raise (Collection_not_fully_defined (curr_spec, vname))
           end)
       end);
      rec_ensure rem_fields in
  (* Now do the job... *)
  rec_ensure fields;
  (* Finally, ckeck if the carrier "rep" was actually found. *)
  if not !rep_found then
    (begin
      match ctx.current_species with
      | None -> assert false
      | Some curr_spec ->
        raise
          (Collection_not_fully_defined (curr_spec, (Parsetree.Vlident "rep")))
     end)
;;



(* ********************************************************************** *)
(** {b Descr} : Helper-type to record the various information from the
              typechecking pass needed to go to the code generation pass.
              This is mostly obvious and self-describing.

    {b Rem} : Clearly exported outside this module.                       *)
(* ********************************************************************** *)
type please_compile_me =
  | PCM_no_matter       (** Nothing to do during the compilation pass. *)
  | PCM_open of (Location.t * Parsetree.modname)
  | PCM_species of
      ((** The species expression. *)
        Parsetree.species_def *
        (** The species description from the typechecking pass, with the
            list of methods contained in its normalized form, with
            "oldestly" inherited in head of the list. *)
        Env.TypeInformation.species_description *
        (** The depency graph of the species's methods. *)
        (Dep_analysis.name_node list))
  | PCM_collection of
      ((** The collection expression. *)
       Parsetree.coll_def *
       (** The collection description from the typechecking pass, with
           the list of methods contained in its normalized form, with
           "oldestly" inherited in head of the list and Self replaced by
           the collection name inside. *)
       Env.TypeInformation.species_description *
         (** The depency graph of the collection's methods. *)
         (Dep_analysis.name_node list))
  | PCM_type of (Parsetree.vname * Env.TypeInformation.type_description)
  | PCM_let_def of (Parsetree.let_def * (Types.type_scheme list))
  | PCM_theorem of Parsetree.theorem_def
  | PCM_expr of Parsetree.expr
;;



(* ************************************************************************* *)
(* typing_context -> Env.TypingEnv.t -> Parsetree.species_def ->             *)
(*  (Types.type_simple * Env.TypingEnv.t)                                    *)
(** {b Descr} : Typechecks a species definition. Il infers its signature and
              bind it to the species name in the environment. Finally, adds
              a type binding representing the species's carrier type.
              Also performs the interface printing stuff of a species.
              It returns both the extended environment and the species's
              carrier type.

    {b Rem} : Not exported outside this module.                              *)
(* ************************************************************************* *)
let typecheck_species_def ctx env species_def =
  let species_def_desc = species_def.Parsetree.ast_desc in
  let current_species =
    (ctx.current_unit, species_def_desc.Parsetree.sd_name) in
  if Configuration.get_verbose () then
    Format.eprintf
      "Typechecking species '%a'.@."
      Sourcify.pp_vname species_def_desc.Parsetree.sd_name;
  (* First of all, we are in a species !!! *)
  let ctx = { ctx with current_species = Some current_species } in
  (* Extend the environment with the species param and   *)
  (* synthetize the species type of the current species. *)
  let (env_with_species_params, sig_params) =
    typecheck_species_def_params
      ctx env species_def_desc.Parsetree.sd_params in
  (* We first load the inherited methods in the environment and  *)
  (* get their signatures and methods information by the way.    *)
  (* We also get a possibly new context where the fact that Self *)
  (* is now manifest is unpdated, in case we inherited a [repr]. *)
  let (inherited_methods_infos,
       env_with_inherited_methods,
       ctx_with_inherited_repr) =
    extend_env_with_inherits
      ~loc: species_def.Parsetree.ast_loc ctx env_with_species_params
      species_def_desc.Parsetree.sd_inherits.Parsetree.ast_desc in
  (* Now infer the types of the current field's and recover *)
  (* the context  where we may know the shape of [repr].    *)
  let (methods_info, ctx', found_proofs_of) =
    typecheck_species_fields
      ctx_with_inherited_repr env_with_inherited_methods
      species_def_desc.Parsetree.sd_fields in
  (* We first collapse "proof-of"s with their *)
  (* related property to lead to a theorem.   *)
  let (collapsed_inherited_methods_infos, collapsed_methods_info) =
    collapse_proofs_of
      ~current_species found_proofs_of inherited_methods_infos methods_info in
  if Configuration.get_verbose () then
    Format.eprintf
      "Normalizing species '%a'.@."
      Sourcify.pp_vname species_def_desc.Parsetree.sd_name;
  (* Create the list of field "semi-normalized", i.e with inherited methods   *)
  (* normalized and in head of the list, and the fresh methods not normalized *)
  (* and in tail of the list.                                                 *)
  let semi_normed_meths =
    collapsed_inherited_methods_infos @ collapsed_methods_info in
  (* Ensure that the species is well-formed. *)
  Dep_analysis.ensure_species_well_formed ~current_species semi_normed_meths;
  (* Then one must ensure that each method has the same type everywhere *)
  (* in the inheritance tree and more generaly create the normalised    *)
  (* form of the species.                                               *)
  let normalized_methods =
    normalize_species
      ~loc: species_def.Parsetree.ast_loc ctx' collapsed_methods_info
      collapsed_inherited_methods_infos in
  (* Now, compute the fields order to prevent ill-formness described in the *)
  (* [collapse_proofs_of] function's header.                                *)
  let new_order =
    Dep_analysis.compute_fields_reordering
      ~current_species normalized_methods in
  (* Now really re-order the normalized fields. *)
  let reordered_normalized_methods =
    order_fields_according_to new_order normalized_methods in
  if Configuration.get_verbose () then
    Format.eprintf
      "Computing dependencies inside species '%a'.@."
      Sourcify.pp_vname species_def_desc.Parsetree.sd_name;
  (* The methods are now completly correct perhaps except for their order  *)
  (* ("correct" i.e. with no multiple times the same name as it can be     *)
  (* before the normalization process), we get its final dependency graph. *)
  let species_dep_graph =
    Dep_analysis.build_dependencies_graph_for_fields
      ~current_species reordered_normalized_methods in
  (* If asked, generate the dotty output of the dependencies. *)
  (match Configuration.get_dotty_dependencies () with
   | None -> ()
   | Some dirname ->
       Dep_analysis.dependencies_graph_to_dotty
         ~dirname ~current_species species_dep_graph);
  (* Check whether the collection is fully defined. If so, then at code  *)
  (* generation-time, then en collection generator must be created. Note *)
  (* that this is independant of the fact to be a collection.            *)
  let is_closed =
    (try
       ensure_collection_completely_defined ctx reordered_normalized_methods;
       (* If the check didn't fail, then the species if fully defined. *)
       true with
     | Collection_not_fully_defined _ -> false) in
  (* Let's build our "type" information. Since we are managing a species *)
  (* and NOT a collection, we must set [spe_is_collection] to [false].   *)
  let species_description = {
    Env.TypeInformation.spe_is_collection = false;
    Env.TypeInformation.spe_is_closed = is_closed;
    Env.TypeInformation.spe_sig_params = sig_params;
    Env.TypeInformation.spe_sig_methods = reordered_normalized_methods } in
  (* Extend the initial environment with the species. Not the environment *)
  (* used to typecheck the internal definitions of the species !!!        *)
  let env_with_species =
    Env.TypingEnv.add_species
      ~loc: species_def.Parsetree.ast_loc
      species_def_desc.Parsetree.sd_name species_description env in
  (* Now, extend the environment with a type that is the species. *)
  Types.begin_definition ();
  let species_carrier_type =
    Types.type_rep_species
      ~species_module: ctx'.current_unit
      ~species_name:
        (Parsetree_utils.name_of_vname species_def_desc.Parsetree.sd_name) in
  Types.end_definition ();
  let species_as_type_description = {
    Env.TypeInformation.type_kind = Env.TypeInformation.TK_abstract;
    Env.TypeInformation.type_identity = Types.generalize species_carrier_type;
    (* Nevers parameters for a species's carrier type ! *)
    Env.TypeInformation.type_params = [];
    Env.TypeInformation.type_arity = 0 } in
  let full_env =
    Env.TypingEnv.add_type
      ~loc: species_def.Parsetree.ast_loc
      species_def_desc.Parsetree.sd_name species_as_type_description
      env_with_species in
  (* Record the type in the AST node. *)
  species_def.Parsetree.ast_type <- Parsetree.ANTI_type species_carrier_type ;
  if Configuration.get_verbose () then
    Format.eprintf
      "Species '%a' accepted.@."
      Sourcify.pp_vname species_def_desc.Parsetree.sd_name ;
  (* Interface printing stuff. *)
  if Configuration.get_do_interface_output () then
    (begin
    Format.printf "@[<2>species %a%a@]@\n"
      Sourcify.pp_vname species_def_desc.Parsetree.sd_name
      Env.TypeInformation.pp_species_description species_description
    end);
  (PCM_species (species_def, species_description, species_dep_graph),
   species_carrier_type, full_env)
;;



(* ************************************************************************ *)
(* typing_context -> is_repr_of_external: bool -> Env.TypingEnv.t ->        *)
(* Parsetree.simple_type_def_body ->                                        *)
(*   (Env.TypingEnv.t * Env.TypeInformation.type_description)               *)
(** {b Descr} : Transforms a simple type definition's body into a somewhat
             that can be inserted inside the environment. Also generates
             type constructors in case of a sum type definition and field
             labels in case of a record type definition.
             The passed context must already have its [tyvars_mapping]
             field initialized, telling the link between the type
             definition's parameters and the type variables they are
             related to.
             Both field labels and constructors with arguments are assigned
             a type scheme like a function taking as argument the field's
             type (or a tuple with type constructor's arguments types) and
             returning a ST_construct embedding the record/sum type's name.
             For instance:
               [type t = A of int]
             will create a constructor [A : (int) -> t]
             where one must note that (int) stands for a degenerated tuple
             type with only 1 component.
             For other instance:
               [type u = { junk : string }]
             will create a field label [junk : string -> u]
             Sum type constructors with no argument are typed as constants
             of this type.
             Also performs the interface printing stuff is needed.

    {b Args} :
      - [~is_repr_of_external] : Boolean telling if the current type
         definition's body is in fact the "internal" representation of an
         external type definition. If it is the case, then the type
         description elaborated will not be inserted in the environment.
         It will only be built (and returned of course), then the guy who
         called us will be in charge to insert the correct type description
         to take into account that the type must not show its sum
         constructors or fields labels in its structure.

    {b Rem} : Not exported outside this module.                             *)
(* ************************************************************************ *)
let typecheck_simple_type_def_body ctx ~is_repr_of_external env type_name
    simple_type_def_body =
  (* Recover on which type variables the parameters are mapped. *)
  let vars_of_mapping = List.map snd ctx.tyvars_mapping in
  (* Get the type constructor's arity. *)
  let nb_params = List.length vars_of_mapping in
  (* Insert ourselves in the environment in case of recursive definition. *)
  Types.begin_definition () ;
  (* Make the type constructor... We know it's vname. Now its hosting *)
  (* module is the current one because it is defined inside it, eh !  *)
  let futur_type_type =
    Types.type_basic
      (Types.make_type_constructor
         ctx.current_unit (Parsetree_utils.name_of_vname type_name))
      vars_of_mapping in
  Types.end_definition () ;
  let proto_identity =
    Types.build_type_def_scheme
      ~variables: vars_of_mapping  ~body: futur_type_type in
  let proto_descrip = {
    (* Make an "abstract" proto-type, even if it is of another kind, this *)
    (* is not important because will never be used.                       *)
    Env.TypeInformation.type_kind = Env.TypeInformation.TK_abstract ;
    Env.TypeInformation.type_identity = proto_identity ;
    Env.TypeInformation.type_params = vars_of_mapping ;
    Env.TypeInformation.type_arity = nb_params } in
  (* Extend the environment with ourselves' proto-type. *)
  let env_with_proto_ourselves =
    Env.TypingEnv.add_type
      ~loc: simple_type_def_body.Parsetree.ast_loc type_name
      proto_descrip env in
  (* Process the body of the type definition. *)
  match simple_type_def_body.Parsetree.ast_desc with
   | Parsetree.STDB_alias ty ->
       (begin
       (* We do not insert the defined name itself  *)
       (* to reject recursive type abbreviations.   *)
       Types.begin_definition () ;
       (* This definition will only add a type name, no new type constructor. *)
       let identity_type =
         typecheck_type_expr ctx env_with_proto_ourselves ty in
       Types.end_definition () ;
       (* Record the type representing this body in the AST node. *)
       simple_type_def_body.Parsetree.ast_type <-
         Parsetree.ANTI_type identity_type ;
       (* Generalize the got type to get the real identity. *)
       let identity_scheme =
         Types.build_type_def_scheme
           ~variables: vars_of_mapping ~body: identity_type in
       let ty_descr = {
         Env.TypeInformation.type_kind = Env.TypeInformation.TK_abstract ;
         Env.TypeInformation.type_identity = identity_scheme ;
         Env.TypeInformation.type_params = vars_of_mapping ;
         Env.TypeInformation.type_arity = nb_params } in
       (* Extend the ORIGINAL environment (not the one where we put our *)
       (* proto-type) by the type itself. Hence we are sur not to have  *)
       (* the type twice.                                               *)
       let env' =
         if is_repr_of_external then env
         else
           Env.TypingEnv.add_type
             ~loc: simple_type_def_body.Parsetree.ast_loc type_name
             ty_descr env in
       (* Return the extended environment and the type description. *)
       (env', ty_descr)
       end)
  | Parsetree.STDB_union constructors ->
    (begin
      (* Now process the constructors of the type. Create the  *)
      (* list of couples : (constructor name * type_simple).   *)
      let cstr_bindings =
        List.map
          (fun (cstr_name, cstr_args) ->
            match cstr_args with
            | [] ->
              (* No argument for the constructor. So it's a constant. *)
              let cstr_descr = {
                Env.TypeInformation.cstr_arity = Env.TypeInformation.CA_zero ;
                Env.TypeInformation.cstr_scheme =
                  Types.generalize futur_type_type } in
              (cstr_name, Env.TypeInformation.CA_zero, cstr_descr)
            | _ ->
              (* There are some argument(s). So the constructor is *)
              (* types as a function taking a tuple of argument(s) *)
              (* and returning the type of the current definition. *)
              Types.begin_definition () ;
              let args_ty =
                List.map
                  (typecheck_type_expr ctx env_with_proto_ourselves)
                  cstr_args in
              (* Make a tuple of the arguments. *)
              let as_tuple = Types.type_tuple args_ty in
              let arrow = Types.type_arrow as_tuple futur_type_type in
              Types.end_definition () ;
              let cstr_descr = {
                Env.TypeInformation.cstr_arity = Env.TypeInformation.CA_one ;
                Env.TypeInformation.cstr_scheme = Types.generalize arrow } in
              (cstr_name, Env.TypeInformation.CA_one, cstr_descr))
          constructors in
      (* And finally, extends the environment with the constructors. *)
      let env_with_constructors =
        List.fold_left
          (fun accu_env (cstr_name, _, cstr_descr) ->
           Env.TypingEnv.add_constructor cstr_name cstr_descr accu_env)
          env
          cstr_bindings in
      (* Record the type representing this body in the AST node. *)
      simple_type_def_body.Parsetree.ast_type <-
        Parsetree.ANTI_type futur_type_type ;
      (* Now add the type itself. *)
      let type_identity =
        Types.build_type_def_scheme
          ~variables: vars_of_mapping ~body: futur_type_type in
      let final_type_descr = {
        Env.TypeInformation.type_kind =
          Env.TypeInformation.TK_variant
            (List.map
               (fun (n, arity, descr) ->
                (n, arity, descr.Env.TypeInformation.cstr_scheme))
               cstr_bindings);
        Env.TypeInformation.type_identity = type_identity ;
        Env.TypeInformation.type_params = vars_of_mapping ;
        Env.TypeInformation.type_arity = nb_params } in
      (* Extend the environment by the type itself. *)
      let env' =
        if is_repr_of_external then env_with_constructors
        else
          Env.TypingEnv.add_type
            ~loc: simple_type_def_body.Parsetree.ast_loc type_name
            final_type_descr env_with_constructors in
      (* Return the extended environment and the type description. *)
      (env', final_type_descr)
     end)
  | Parsetree.STDB_record labels ->
      (* First, we sort the label list in order to get a canonical *)
      (* representation of a record.                               *)
      let labels = Sort.list (fun (n1, _) (n2, _) -> n1 <= n2) labels in
      (* Now typecheck the fields of the record. *)
      let fields_descriptions =
        List.map
          (fun (lbl_name, lbl_ty_expr) ->
            Types.begin_definition ();
            let lbl_ty =
              typecheck_type_expr ctx env_with_proto_ourselves lbl_ty_expr in
            let arrow = Types.type_arrow lbl_ty futur_type_type in
            Types.end_definition ();
            let lbl_scheme = Types.generalize arrow in
            (* Currently, fields do not support the "mutable" tag. *)
            (lbl_name, { Env.TypeInformation.field_mut =
                           Env.TypeInformation.FM_immutable ;
                         Env.TypeInformation.field_scheme = lbl_scheme }))
          labels in
      (* And finally, extends the environment with the labels. *)
      let env_with_labels =
        List.fold_left
          (fun accu_env (lbl_name, lbl_descr) ->
            Env.TypingEnv.add_label lbl_name lbl_descr accu_env)
          env
          fields_descriptions in
      (* Record the type representing this body in the AST node. *)
      simple_type_def_body.Parsetree.ast_type <-
        Parsetree.ANTI_type futur_type_type ;
      (* Now add the type itself. *)
      let type_identity =
        Types.build_type_def_scheme
          ~variables: vars_of_mapping ~body: futur_type_type in
      let final_type_descr = {
        Env.TypeInformation.type_kind =
          Env.TypeInformation.TK_record
            (List.map
               (fun (lbl_name, lbl_descr) ->
                 (lbl_name,
                  lbl_descr.Env.TypeInformation.field_mut,
                  lbl_descr.Env.TypeInformation.field_scheme))
               fields_descriptions);
          Env.TypeInformation.type_identity = type_identity ;
          Env.TypeInformation.type_params = vars_of_mapping ;
          Env.TypeInformation.type_arity = nb_params } in
      (* Extend the environment by the type itself. *)
    let env' =
      if is_repr_of_external then env_with_labels
      else
        Env.TypingEnv.add_type
          ~loc: simple_type_def_body.Parsetree.ast_loc
          type_name final_type_descr env_with_labels in
    (* Return the extended environment and the type description. *)
    (env', final_type_descr)
;;



(* ************************************************************************* *)
(** {b Descr} : Typecheck the body of an external type definition. If the
      definition doesn't have any "internal" representation, the type is
      considered as fully abstract. I.e. it has no mapping onto the FoCaL
      type algebra. The type name is then mapped onto a [ST_construct] with
      it's name as parameter of the [ST_construct] constructor.
      We return the typing environment extended by the bindings induced by
      the definition and the description of the type definition as entered
      in the environment's structure.
      Note that in the returned environment, there are not the type
      variables representing the parameters ! They are in the variable
      mapping of the context. Hence there is no risk to see them escaping
      outside the type's definition.

    {b Args} :
      - [ctx] : The current typing context in which the "variable mapping"
           (i.e. mapping from the definition's parameters to type variables)
            is already recorded.

      - [type_name] : The name of the type definition (i.e. the name of
          the type constructor defined by this ... definition).

      - [env] : The current typing environment (which will be extented by
          the current typechecking process).

      - [params] : The positionnal list of type variables the type
          definition's parameters are related to.

      - [external_type_def_body] : The external definition's body to
          typecheck.

    {b Rem} : Not exported outside this module.                              *)
(* ************************************************************************* *)
let typecheck_external_type_def_body ctx env type_name params
    external_type_def_body =
  (* An external type definition "has no type". Record in the AST node. *)
  external_type_def_body.Parsetree.ast_type <- Parsetree.ANTI_non_relevant ;
  (* Same remark for the [external_expr] and the [external_bindings] *)
  (* telling how to map this external type definition.               *)
  external_type_def_body.Parsetree.ast_desc.Parsetree.etdb_external.
    Parsetree.ast_type <- Parsetree.ANTI_non_relevant ;
  external_type_def_body.Parsetree.ast_desc.Parsetree.etdb_bindings.
    Parsetree.ast_type <- Parsetree.ANTI_non_relevant ;
  List.iter
    (fun ext_binding ->
      ext_binding.Parsetree.ast_type <- Parsetree.ANTI_non_relevant ;
      (* Propagate into the [external_expr] of the [external_binding]. *)
      let (_, ext_expr) = ext_binding.Parsetree.ast_desc in
      ext_expr.Parsetree.ast_type <- Parsetree.ANTI_non_relevant)
    external_type_def_body.Parsetree.ast_desc.Parsetree.etdb_bindings.
      Parsetree.ast_desc ;
  (* We build the type's structure and the environment where *)
  (* this type's name is bound to this structure.            *)
  match external_type_def_body.Parsetree.ast_desc.Parsetree.etdb_internal with
   | None ->
       (begin
       (* We will build an external type of this name with as many *)
       (* parameters we find in the [ctx.tyvars_mapping] list.     *)
       Types.begin_definition () ;
       (* Make the type constructor... We know it's vname. Now its hosting *)
       (* module is the current one because it is defined inside it, eh !  *)
       let ty =
         Types.type_basic
           (Types.make_type_constructor
              ctx.current_unit
              (Parsetree_utils.name_of_vname type_name))
           params in
       Types.end_definition () ;
       let identity =
         Types.build_type_def_scheme ~variables: params ~body: ty in
       (* And now make the type's description to insert in the environment. *)
       let ty_descr = {
         Env.TypeInformation.type_kind =
           Env.TypeInformation.TK_external
             (external_type_def_body.Parsetree.ast_desc.Parsetree.etdb_external,
             external_type_def_body.Parsetree.ast_desc.Parsetree.etdb_bindings);
         Env.TypeInformation.type_identity = identity ;
         Env.TypeInformation.type_params = params ;
         Env.TypeInformation.type_arity = List.length params } in
       if Configuration.get_do_interface_output () then
         (begin
         Format.printf "@[<2>external@ type %a@ =@ %a@]@\n"
           Sourcify.pp_vname type_name Types.pp_type_scheme identity
         end) ;
       (* Return the extended environment. *)
       let final_env =
         Env.TypingEnv.add_type
           ~loc: external_type_def_body.Parsetree.ast_loc type_name ty_descr
           env in
       (final_env, ty_descr)
       end)
   | Some internal_repr ->
       (* Build the type structure of the "internal" representation. This *)
       (* will be used to build the real type's structure.                *)
       let (env_without_type_def, internal_descr) =
         typecheck_simple_type_def_body
           ctx ~is_repr_of_external: true env type_name internal_repr in
       (* Force the type to be [TK_external] in order to prevent ot from  *)
       (* being "generated". Even if this type has an internal structure, *)
       (* the generated code must always map on its external view !       *)
       let externalized_descr = {
         internal_descr with
           Env.TypeInformation.type_kind =
             Env.TypeInformation.TK_external
               (external_type_def_body.Parsetree.ast_desc.
                 Parsetree.etdb_external,
                external_type_def_body.Parsetree.ast_desc.
                  Parsetree.etdb_bindings) } in
       let final_env =
         Env.TypingEnv.add_type
           ~loc: internal_repr.Parsetree.ast_loc type_name
         externalized_descr env_without_type_def in
       (final_env, externalized_descr)
;;



let typecheck_type_def ctx env type_def =
  let type_def_desc = type_def.Parsetree.ast_desc in
  (* A type definition "has no type". Record in the AST node. *)
  type_def.Parsetree.ast_type <- Parsetree.ANTI_non_relevant ;
  type_def_desc.Parsetree.td_body.Parsetree.ast_type <-
    Parsetree.ANTI_non_relevant ;
  (* First, extend the [tyvars_mapping] of the current context with      *)
  (* parameters of the type definition. The position of variables in the *)
  (* mapping is and must be the same that in the type's parameters list. *)
  Types.begin_definition () ;
  let vmapp =
    List.map
      (fun var_name -> (var_name, Types.type_variable ()))
      type_def_desc.Parsetree.td_params in
  Types.end_definition () ;
  let new_ctx = { ctx with tyvars_mapping = vmapp } in
  match type_def_desc.Parsetree.td_body.Parsetree.ast_desc with
   | Parsetree.TDB_simple simple_def_body ->
       typecheck_simple_type_def_body
         new_ctx ~is_repr_of_external: false env
         type_def_desc.Parsetree.td_name simple_def_body
   | Parsetree.TDB_external external_type_def_body ->
       typecheck_external_type_def_body
         new_ctx env type_def_desc.Parsetree.td_name
         (List.map snd vmapp) external_type_def_body
;;




(* ****************************************************************** *)
(* typing_context -> Env.TypingEnv.t -> Parsetree.coll_def ->         *)
(*   (Types.type_simple * Env.TypingEnv.t)                            *)
(** {b Descr} : Typecheck a definition of collection. It recovers its
              fields and their types and verifies that the resulting
              species is fully defined.
              Once the collection is successfully built, it is added
              to the current environment.
              The function returns both the extended environment and
              the carrier type pf the species.

    {b Args} :
      - [ctx] : Current structure recording the various information
              required and propagated to typecheck.
      - [env] : The current typing environment mapping identifiers
              onto types.
      - [coll_def] : Collection definition to typecheck.

    {b Rem} : Not exported outside this module.                       *)
(* ****************************************************************** *)
let typecheck_collection_def ctx env coll_def =
  let coll_def_desc = coll_def.Parsetree.ast_desc in
  if Configuration.get_verbose () then
    Format.eprintf "Typechecking collection '%a'.@."
      Sourcify.pp_vname coll_def_desc.Parsetree.cd_name ;
  let current_species = (ctx.current_unit, coll_def_desc.Parsetree.cd_name) in
  (* First of all, we are in a species !!! *)
  let ctx = { ctx with current_species = Some current_species } in
  (* Typecheck the body's species expression .*)
  let species_expr_fields =
    typecheck_species_expr ctx env coll_def_desc.Parsetree.cd_body in
  (* One must ensure that the collection is *)
  (* really a completely defined species.   *)
  ensure_collection_completely_defined ctx species_expr_fields ;
  let myself_coll_ty =
    (ctx.current_unit,
     (Parsetree_utils.name_of_vname coll_def_desc.Parsetree.cd_name)) in
  (* In the collection's fields, substitute Self <- the collection name. *)
  let collection_fields =
    List.map
      (SubstColl.subst_species_field
         ~current_unit: ctx.current_unit SubstColl.SCK_self myself_coll_ty)
      species_expr_fields in
  (* Get the dependencies graph of the species. *)
  if Configuration.get_verbose () then
    Format.eprintf
      "Computing dependencies inside collection '%a'.@."
      Sourcify.pp_vname coll_def_desc.Parsetree.cd_name ;
  let collection_dep_graph =
    Dep_analysis.build_dependencies_graph_for_fields
      ~current_species collection_fields in
  (* If asked, generate the dotty output of the dependencies. *)
  (match Configuration.get_dotty_dependencies () with
   | None -> ()
   | Some dirname ->
       Dep_analysis.dependencies_graph_to_dotty
         ~dirname ~current_species collection_dep_graph);
  (* Let's build our "type" information. Since we are managing a species *)
  (* and NOT a collection, we must set [spe_is_collection] to [false].   *)
  let collec_description = {
    Env.TypeInformation.spe_is_collection = true;
    Env.TypeInformation.spe_is_closed = true;  (* Obviously, eh ! *)
    Env.TypeInformation.spe_sig_params = [];
    Env.TypeInformation.spe_sig_methods = collection_fields } in
  (* Add this collection in the environment. *)
  let env_with_collection =
    Env.TypingEnv.add_species
      ~loc: coll_def.Parsetree.ast_loc
      coll_def_desc.Parsetree.cd_name collec_description env in
  (* Now, extend the environment with a type that is this collection. *)
  Types.begin_definition () ;
  let collec_carrier_type =
    Types.type_rep_species
      ~species_module: ctx.current_unit
      ~species_name:
        (Parsetree_utils.name_of_vname coll_def_desc.Parsetree.cd_name) in
  Types.end_definition () ;
  let collec_as_type_description = {
    Env.TypeInformation.type_kind = Env.TypeInformation.TK_abstract;
    Env.TypeInformation.type_identity = Types.generalize collec_carrier_type;
    (* Nevers parameters for a species's carrier type ! *)
    Env.TypeInformation.type_params = [] ;
    Env.TypeInformation.type_arity = 0 } in
  let full_env =
    Env.TypingEnv.add_type
      ~loc: coll_def.Parsetree.ast_loc
      coll_def_desc.Parsetree.cd_name collec_as_type_description
      env_with_collection in
  (* Record the type in the AST node. *)
  coll_def.Parsetree.ast_type <- Parsetree.ANTI_type collec_carrier_type ;
  (* Interface printing stuff. *)
  if Configuration.get_do_interface_output () then
    Format.printf "@[<2>collection %a%a@]@\n"
      Sourcify.pp_vname coll_def_desc.Parsetree.cd_name
      Env.TypeInformation.pp_species_description collec_description;
  (PCM_collection (coll_def, collec_description, collection_dep_graph),
   collec_carrier_type, full_env)
;;



(* ****************************************************************** *)
(* typing_context -> Env.TypingEnv.t -> Parsetree.phrase ->           *)
(*   (please_compile_me * Env.TypingEnv.t)                            *)
(** {b Descr} : Performs type inference on a [phrase] and returns the
                initial environment extended with the possible type
        bindings induced by the [phrase].
                Also assign the infered type in the [ast_type] field
                of the [phrase] node.

    {b Rem} : Not exported outside this module                        *)
(* ****************************************************************** *)
let typecheck_phrase ctx env phrase =
  match phrase.Parsetree.ast_desc with
   | Parsetree.Ph_use _ ->
       (* Store the type information in the phrase's node. *)
       phrase.Parsetree.ast_type <- Parsetree.ANTI_non_relevant ;
       (* Nothing to do, the scoping pass already ensured that *)
       (* "modules" opened or used were previously "use"-d.    *)
       (PCM_no_matter, env)
   | Parsetree.Ph_open fname ->
       (* Load this module interface to extend the current environment. *)
       let env' =
         Env.type_open_module ~loc: phrase.Parsetree.ast_loc fname env in
       (* Store the type information in the phrase's node. *)
       phrase.Parsetree.ast_type <- Parsetree.ANTI_non_relevant ;
       ((PCM_open (phrase.Parsetree.ast_loc, fname)), env')
   | Parsetree.Ph_species species_def ->
       (* Interface printing stuff is done inside. *)
       let (compil_info, ty, env') =
         typecheck_species_def ctx env species_def  in
       (* Store the type information in the phrase's node. *)
       phrase.Parsetree.ast_type <- Parsetree.ANTI_type ty ;
       (compil_info, env')
   | Parsetree.Ph_coll coll_def ->
       (* Interface printing stuff is done inside. *)
       let (compil_info, ty, env') =
         typecheck_collection_def ctx env coll_def in
       (* Store the type information in the phrase's node. *)
       phrase.Parsetree.ast_type <- Parsetree.ANTI_type ty ;
       (compil_info, env')
   | Parsetree.Ph_type type_def ->
       let (env', ty_descr) = typecheck_type_def ctx env type_def in
       (* Interface printing stuff must be bone inside. *)
       if Configuration.get_do_interface_output () then
         Format.printf "type ... @\n" ;  (* [Unsure] TODO. *)
       (* Store the type information in the phrase's node. *)
       phrase.Parsetree.ast_type <- Parsetree.ANTI_non_relevant ;
       ((PCM_type (type_def.Parsetree.ast_desc.Parsetree.td_name, ty_descr)),
        env')
   | Parsetree.Ph_let let_def  ->
       let envt_bindings =
         typecheck_let_definition ~is_a_field: false ctx env let_def in
       (* Extend the current environment with the *)
       (* bindings induced the let-definition.    *)
       let env' =
         List.fold_left
           (fun accu_env (id, ty_scheme) ->
             (* Interface printing stuff. *)
             if Configuration.get_do_interface_output () then
               Format.printf "val %a in %a@\n"
                 Sourcify.pp_vname id Types.pp_type_scheme ty_scheme;
             (* Extend the environment with the current binding. *)
             Env.TypingEnv.add_value id ty_scheme accu_env)
           env envt_bindings in
       (* Just recover the type scheme of each bound identifier. *)
       let bound_schemes = List.map snd envt_bindings in
       (* Store the type information in the phrase's node. *)
       phrase.Parsetree.ast_type <- Parsetree.ANTI_non_relevant ;
       (* Return unit and the extended environment. *)
       ((PCM_let_def (let_def, bound_schemes)), env')
   | Parsetree.Ph_theorem theorem_def ->
       Types.begin_definition () ;
       let ty = typecheck_theorem_def ctx env theorem_def in
       Types.end_definition () ;
       let scheme = Types.generalize ty in
       let env' =
         Env.TypingEnv.add_value
           theorem_def.Parsetree.ast_desc.Parsetree.th_name scheme env in
       (* Interface printing stuff. *)
       if Configuration.get_do_interface_output () then
         Format.printf "theorem %a in %a@\n"
           Sourcify.pp_vname theorem_def.Parsetree.ast_desc.Parsetree.th_name
           Types.pp_type_simple ty ;
       (* Store the type information in the phrase's node. *)
       phrase.Parsetree.ast_type <- Parsetree.ANTI_scheme scheme ;
       ((PCM_theorem theorem_def), env')
   | Parsetree.Ph_expr expr ->
       let expr_ty = typecheck_expr ctx env expr in
       (* Store the type information in the phrase's node. *)
       phrase.Parsetree.ast_type <- Parsetree.ANTI_type expr_ty ;
       (* No interface printing stuff because the expression is not bound. *)
       ((PCM_expr expr), env)
;;



(* ********************************************************************* *)
(* current_unit: Types.fname -> Parsetree.file ->                        *)
(*   (Env.TypingEnv.t * (please_compile_me list))                        *)
(** {b Descr} : Performs type inference on a complete FoCaL source file.

    {b Rem} : Exported outside this module.                              *)
(* ********************************************************************* *)
let typecheck_file ~current_unit ast_file =
  match ast_file.Parsetree.ast_desc with
   | Parsetree.File phrases ->
     (* A file is always typed in an empty context. *)
     let ctx = {
       current_unit = current_unit ;
       current_species = None ;
       self_manifest = None ;
       tyvars_mapping = [] } in
     let global_env = ref (Env.TypingEnv.pervasives ()) in
     let what_to_compile =
       List.map
         (fun phrase ->
          let (stuff_to_compile, new_global_env) =
            typecheck_phrase ctx !global_env phrase in
          (* Make the global typing environment growing by side effect. *)
          global_env := new_global_env ;
          stuff_to_compile)
         phrases in
     (* Store the type information in the phrase's node. A file has no type. *)
     ast_file.Parsetree.ast_type <- Parsetree.ANTI_non_relevant ;
     (!global_env, what_to_compile)
;;
