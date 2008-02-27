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

(* $Id: misc_ml_generation.mli,v 1.12 2008-02-27 13:42:49 pessaux Exp $ *)



val pp_to_ocaml_label_ident : Format.formatter -> Parsetree.label_ident -> unit

type reduced_compil_context = {
  rcc_current_unit : Types.fname ;
  rcc_species_parameters_names : Parsetree.vname list ;
  rcc_collections_carrier_mapping : (Types.type_collection * string) list ;
  rcc_lambda_lift_params_mapping :
    (Parsetree.vname * ((string * Types.type_simple )list)) list ;
  rcc_out_fmter : Format.formatter
}
