(*  Copyright 2004 INRIA  *)
(*  $Id: prio.mli,v 1.4 2004-09-28 13:12:58 doligez Exp $  *)

type shape =
  | Close      (* 0 *)
  | Alpha1     (* 1 *)
  | Delta      (* 1 *)
  | Alpha2     (* 2 *)
  | Beta1      (* 3 *)
  | Gamma_meta (* 3 *)
  | Beta2      (* 4 *)
  | Correl     (* 5 *)
  | Gamma_inst of Expr.expr (* 6 *)
  | Gamma_inst_partial (* 6 *)
;;

type t = int;;

val make : int -> shape -> Expr.expr list array -> t;;
