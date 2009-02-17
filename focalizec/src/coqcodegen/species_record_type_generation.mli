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

(* $Id: species_record_type_generation.mli,v 1.16 2009-02-17 16:20:21 pessaux Exp $ *)


type self_methods_status =
  | SMS_from_param of Parsetree.vname
  | SMS_abstracted
  | SMS_from_record

val make_Self_cc_binding_abst_T :
  current_species: Parsetree.qualified_species ->
    (Types.type_collection * (string * Types.collection_carrier_mapping_info))

val make_Self_cc_binding_rf_T : 
  current_species: Parsetree.qualified_species ->
    (Types.type_collection * (string * Types.collection_carrier_mapping_info))

val make_Self_cc_binding_species_param :
  current_species: Parsetree.qualified_species -> Parsetree.vname ->
    (Types.type_collection * (string * Types.collection_carrier_mapping_info))

val generate_method_lambda_lifted_arguments :
  Format.formatter -> Parsetree.vname list ->
    (Env.TypeInformation.species_param *
     Env.ordered_methods_from_params) list ->
       Parsetree.vname list -> unit

val generate_pattern :
  Context.species_compil_context -> Env.CoqGenEnv.t -> Parsetree.pattern -> unit

val generate_expr :
  Context.species_compil_context ->
    in_recursive_let_section_of: Parsetree.vname list ->
      local_idents: Parsetree.vname list ->
        self_methods_status: self_methods_status -> Env.CoqGenEnv.t ->
          Parsetree.expr -> unit

val generate_logical_expr :
  Context.species_compil_context ->
    in_recursive_let_section_of: Parsetree.vname list ->
      local_idents: Parsetree.vname list ->
        self_methods_status: self_methods_status -> Env.CoqGenEnv.t ->
      Parsetree.logical_expr -> unit

val let_binding_compile :
  Context.species_compil_context ->
    in_recursive_let_section_of: Parsetree.vname list ->
      local_idents: Parsetree.vname list ->
        self_methods_status: self_methods_status -> is_rec: bool ->
          toplevel: bool -> Env.CoqGenEnv.t -> Parsetree.binding ->
            Env.CoqGenEnv.t

val generate_record_type :
  Context.species_compil_context ->
    Env.CoqGenEnv.t -> Env.TypeInformation.species_description ->
      Abstractions.field_abstraction_info list ->
	(Parsetree.vname * Env.ordered_methods_from_params) list
