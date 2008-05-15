(***********************************************************************)
(*                                                                     *)
(*                        FoCaL compiler                               *)
(*            William Bartlett                                         *)
(*            Fran�ois Pessaux                                         *)
(*            Pierre Weis                                              *)
(*            Damien Doligez                                           *)
(*                               LIP6  --  INRIA Rocquencourt          *)
(*                                                                     *)
(*  Copyright 2007 LIP6 and INRIA                                      *)
(*  Distributed only by permission.                                    *)
(*                                                                     *)
(***********************************************************************)

(* $Id: recursion.mli,v 1.3 2008-04-23 14:54:07 pessaux Exp $ *)

exception NestedRecursiveCalls of Parsetree.vname * Location.t
exception PartialRecursiveCall of Parsetree.vname * Location.t
exception MutualRecursion

type binding =
  | B_let of Parsetree.binding
  | B_match of (Parsetree.expr * Parsetree.pattern)
  | B_condition of (Parsetree.expr * bool)

val list_recursive_calls:
  Parsetree.vname ->
  Parsetree.vname list ->
  binding list ->
  Parsetree.expr ->
  ((Parsetree.vname * Parsetree.expr) list * binding list) list

val is_structural:
  Parsetree.vname ->
  Parsetree.vname list ->
  Parsetree.vname ->
  Parsetree.expr ->
  bool