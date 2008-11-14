(*  Copyright 2004 INRIA  *)
(*  $Id: phrase.mli,v 1.11 2008-11-14 20:28:02 doligez Exp $  *)

open Expr;;

type inductive_arg =
  | Param of string
  | Self
;;

type phrase =
  | Hyp of string * expr * int
  | Def of definition
  | Sig of string * string list * string  (* sym, args, result *)
  | Inductive of string * string list * (string * inductive_arg list) list
;;

type zphrase =
  | Zhyp of string * expr * int
  | Zdef of definition
  | Zsig of string * string list * string
  | Zinductive of string * string list * (string * inductive_arg list) list
  | Zinclude of string
;;

val separate : phrase list -> definition list * (expr * int) list;;

type tpphrase =
  | Include of string
  | Formula of string * string * expr
  | Annotation of string
;;

val change_to_def : expr -> definition;;
(** Turn a def-shaped formula into a (real) definition.
    Raise [Invalid_argument] if the argument is not def-shaped. *)
