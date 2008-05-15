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

(* $Id: externals_generation_errs.ml,v 1.1 2008-04-09 10:19:44 pessaux Exp $ *)


(* ************************************************************************ *)
(** {b Descr} : Exception raised when an external value definition does not
              not provides any correspondance with a language.

    {b Rem} : Exported outside this module.                                 *)
(* ************************************************************************ *)
exception No_external_value_def of (
  string *            (** The language name ("OCaml", "Coq", "..."). *)
  Parsetree.vname *   (** The primitive that was not mapped. *)
  Location.t) ;;      (** The location where the mapping could not be done. *)



(* ************************************************************************ *)
(** {b Descr} : Exception raised when an external type definition does not
              not provides any correspondance with a language.

    {b Rem} : Exported outside this module.                                 *)
(* ************************************************************************ *)
exception No_external_type_def of (string * Parsetree.vname * Location.t)
;;



(* ************************************************************************ *)
(** {b Descr} : Exception raised when an external type sum type definition
         named a sum constructor but didn't provided any correspondance
         with a language. The location of the error is self-contained in
        the [constructor_ident].

    {b Rem} : Exported outside this module.                                 *)
(* ************************************************************************ *)
exception No_external_constructor_def of
  (string * Parsetree.constructor_ident) ;;



(* ********************************************************************* *)
(** {b Descr} : Exception raised when an external type record type
         definition named a field but didn't provided any correspondance
         with a language. The location of the error is self-contained in
         the [label_ident].

    {b Rem} : Exported outside this module.                              *)
(* ********************************************************************* *)
exception No_external_field_def of (string * Parsetree.label_ident) ;;