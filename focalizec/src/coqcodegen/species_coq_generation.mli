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

(* $Id: species_coq_generation.mli,v 1.10 2008-12-01 14:40:43 pessaux Exp $ *)

exception Attempt_proof_by_def_of_species_param of
  (Location.t * Parsetree.expr_ident)

exception Attempt_proof_by_def_of_declared_method_of_self of
  (Location.t * Parsetree.expr_ident)

exception Attempt_proof_by_def_of_local_ident of
  (Location.t * Parsetree.expr_ident)

exception Attempt_proof_by_prop_of_local_ident of
  (Location.t * Parsetree.expr_ident)

exception Attempt_proof_by_unknown_hypothesis of (Location.t * Parsetree.vname)

exception Attempt_proof_by_unknown_step of (Location.t * Parsetree.node_label)

exception Termination_is_not_structural of (Location.t * Parsetree.vname)

val generate_defined_recursive_let_definition_non_structural :
  Context.species_compil_context ->
  Coq_pprint.coq_print_context ->
  Env.CoqGenEnv.t ->
  self_manifest: Types.type_simple option ->
  Misc_common.compiled_species_fields list ->
  Env.from_history ->
  Parsetree.vname ->
  Parsetree.vname list ->
  Types.type_scheme ->
  Parsetree.binding_body ->
  Parsetree.termination_proof_desc Parsetree.ast option ->
  Env.TypeInformation.field_abstraction_info ->
  Misc_common.compiled_field_memory

val generate_defined_recursive_let_definition_structural :
  Context.species_compil_context ->
  Coq_pprint.coq_print_context ->
  Env.CoqGenEnv.t ->
  Misc_common.compiled_species_fields list ->
  Env.from_history ->
  Parsetree.vname ->
  Parsetree.vname list ->
  Parsetree.vname ->
  Location.t ->
  Types.type_scheme ->
  Parsetree.binding_body ->
  Env.TypeInformation.field_abstraction_info ->
  self_manifest:Types.type_simple option -> is_first: bool -> is_last: bool ->
    Misc_common.compiled_field_memory

val species_compile :
  Env.CoqGenEnv.t -> current_unit: Types.fname -> Format.formatter ->
    Parsetree.species_def_desc Parsetree.ast ->
      Env.TypeInformation.species_description ->
        DepGraphData.name_node list ->
          (Parsetree.vname * Env.TypeInformation.field_abstraction_info) list ->
          (Env.TypeInformation.species_param list *
           Env.CoqGenInformation.method_info list *
           (Env.CoqGenInformation.collection_generator_info option) *
           Env.collection_or_species)

val collection_compile :
  Env.CoqGenEnv.t -> current_unit: Types.fname -> Format.formatter ->
    Parsetree.collection_def_desc Parsetree.ast ->
      Env.TypeInformation.species_description ->
        DepGraphData.name_node list ->
          Env.CoqGenInformation.method_info list

val toplevel_theorem_compile :
  Context.species_compil_context -> Env.CoqGenEnv.t ->
    Parsetree.theorem_def -> Parsetree.vname list
