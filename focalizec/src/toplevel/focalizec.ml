(***********************************************************************)
(*                                                                     *)
(*                        FoCaL compiler                               *)
(*            Pierre Weis                                              *)
(*            Damien Doligez                                           *)
(*            Fran�ois Pessaux                                         *)
(*                               LIP6  --  INRIA Rocquencourt          *)
(*                                                                     *)
(*  Copyright 2007 LIP6 and INRIA                                      *)
(*  Distributed only by permission.                                    *)
(*                                                                     *)
(***********************************************************************)

(* $Id: focalizec.ml,v 1.2 2007-07-30 08:07:44 weis Exp $ *)

(** The focalize concrete syntax file checker. *)

open Format;;

(* The main procedure *)
let main () =
  Arg.parse
    [ ("-v", Arg.Unit Configuration.print_focal_short_version,
       " print the focalize version.");
      ("--version",
       Arg.Unit Configuration.print_focal_full_version,
       " print the full focalize version, sub-version and release date.");
      ("-c",
       Arg.String Configuration.set_input_file_name,
       " check input file argument.");
      ("--pretty",
       Arg.String Configuration.set_pretty_print,
       " pretty-prints the parse tree of the focal file as a focal source.");
      ("--old-pretty",
       Arg.String Configuration.set_old_pretty_print,
       " pretty-prints the parse tree of the focalize file as \
         an old focal source.");
      ("--typecheck",
       Arg.Unit (fun () -> Configuration.set_do_typechecking true),
       " performs type inference.");
      ("--verbose",
       Arg.Unit (fun () -> Configuration.set_verbose true),
       " be verbose.") ]
    Configuration.set_input_file_name
    "Usage: focal_check <options> <.foc file>";
  (* First, let's lex and parse the input source file. *)
  let ast =
    Parse_file.parse_file
      err_formatter (Configuration.get_input_file_name ()) in
  (* Hard-dump the AST if requested. *)
  if Configuration.get_verbose () then
    Dump_ptree.pp_file err_formatter ast;
  (* Pretty the AST as a new-focal-syntax source if requested. *)
  (match Configuration.get_pretty_print () with
   | None -> ()
   | Some fname ->
       let out_hd = open_out_bin fname in
       let out_fmt = formatter_of_out_channel out_hd in
       Sourcify.pp_file out_fmt ast;
       close_out out_hd);
  (* Pretty the AST as an old-focal-syntax source if requested. *)
  (match Configuration.get_old_pretty_print () with
   | None -> ()
   | Some fname ->
     let out_hd = open_out_bin fname in
     let out_fmt = formatter_of_out_channel out_hd in
     Oldsourcify.pp_file out_fmt ast;
     close_out out_hd);
  (* Typechecks the AST if requested. *)
  if Configuration.get_do_typechecking () then
    Infer.typecheck_file ast;
  exit 0
;;

(** If something unexpected arises when proceeding, we exit with the proper
    error code. *)
try main () with
| Types.Conflict (ty1, ty2) ->
    fprintf err_formatter
      "Type incompatibility between %a@ and@ %a.@."
      Types.pp_type_simple ty1 Types.pp_type_simple ty2;
| Types.Circularity (ty1, ty2) ->
    fprintf err_formatter
      "Circulary between types %a@ and@ %a@."
      Types.pp_type_simple ty1 Types.pp_type_simple ty2
| Types.Arity_mismatch (cstr_name, arity1, arity2) ->
    fprintf err_formatter
      "Type constructor %s used with arity %d and %d@."
      cstr_name arity1 arity2
| Env.Unbound_identifier vname ->
    fprintf err_formatter "Unbound identifier \"%s\".@."
      (Parsetree_utils.name_of_vname vname)
| Parse_file.Lex_error (pos_s, pos_e, reason) ->
    fprintf err_formatter "Lexical error, %a. %s@."
      Parse_file.pp_err_loc (pos_s, pos_e) reason
| Parse_file.Syntax_error position ->
    fprintf err_formatter "Syntax error, %a.@."
      Parse_file.pp_err_loc position
| Parse_file.Unclear_error position ->
    fprintf err_formatter "Unclear syntax error, %a.@."
      Parse_file.pp_err_loc position
| x ->
    fprintf err_formatter
      "Unexpected error: \"%s\".\nPlease report.@."
      (Printexc.to_string x);
    exit 2
;;
