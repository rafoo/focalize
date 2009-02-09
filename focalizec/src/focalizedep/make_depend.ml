(***********************************************************************)
(*                                                                     *)
(*                        FoCaLize compiler                            *)
(*                                                                     *)
(*            Fran�ois Pessaux                                         *)
(*            Pierre Weis                                              *)
(*            Damien Doligez                                           *)
(*                                                                     *)
(*                               LIP6  --  INRIA Rocquencourt          *)
(*                                                                     *)
(*  Copyright 2007, 2008 LIP6 and INRIA                                *)
(*  Distributed only by permission.                                    *)
(*                                                                     *)
(***********************************************************************)

(* $Id: make_depend.ml,v 1.1 2009-02-09 10:55:59 pessaux Exp $ *)


(* *********************************************************************** *)
(** {b Descr}: The name of the file where we store the dependencies in the
    format "make" expects.

    {b Rem}: Not exported outside this module.                             *)
(* *********************************************************************** *)
module CompUnitMod = struct
  type t = Parsetree.module_name
  let compare = compare
end ;;
module CompUnitSet = Set.Make (CompUnitMod) ;;



(* ********************************************************************** *)
(** {b Descr}: Describes for the compilation unit [fd_comp_unit] the set
    of compilation it has compilation (i.e. for make) dependencies it has
    on.

    {b Rem}: Not exported outside this module.                            *)
(* ********************************************************************** *)
type file_dependency = {
  fd_comp_unit : Parsetree.module_name ;  (** Base name without extension of
                                              the file for which we compute the
                                              dependencies. In other words,
                                              what we call a "compilation
                                              unit". *)
  fd_dependencies : CompUnitSet.t (** Base name without extension of the files
                                      we (i.e.[fd_comp_unit]) depend on. *)
} ;;



(* ******************************************************************* *)
(* string -> bool                                                      *)
(** {b Descr}: Check if the file is a FoCaLize source file (i.e. has a
    ".fcl"suffix and is not an Emacs temporary or backup file.

    {b Rem}: Not exported outside this module.                         *)
(* ******************************************************************* *)
let is_focalize_file n =
  if not (Filename.check_suffix n ".fcl") || (String.length n = 0) then false
  else
    match n.[0] with
     | '#' | '.' ->
         (* We don't analyse emacs buffers, and temporary files. *)
         false
     | _ -> true
;;



let process_one_file fname =
  let in_hd = open_in_bin fname in
  let lexbuf = Lexing.from_channel in_hd in
  let continue = ref true in
  let comp_units = ref CompUnitSet.empty in
  while !continue do
    match Directive_lexer.start lexbuf with
     | Directive_lexer.D_end -> continue := false
     | Directive_lexer.D_found mod_name ->
         comp_units := CompUnitSet.add mod_name !comp_units
  done ;
  close_in in_hd ;
  let basename = Filename.chop_suffix (Filename.basename fname) ".fcl" in
  { fd_comp_unit = basename ;
    fd_dependencies = !comp_units }
;;



let make_targets deps =
  let basename = deps.fd_comp_unit in
  (* Handle dependencies for .fo files. *)
  Printf.printf "%s.fo:" basename ;
  CompUnitSet.iter
    (fun n -> Printf.printf " %s.fo" n)
    deps.fd_dependencies ;
  Printf.printf "\n" ;
  (* Handle dependencies for .ml files. *)
  Printf.printf "%s.ml:" basename ;
  CompUnitSet.iter
    (fun n -> Printf.printf " %s.ml" n)
    deps.fd_dependencies ;
  Printf.printf "\n" ;
  (* Handle dependencies for .zv files. *)
  Printf.printf "%s.zv:" basename ;
  CompUnitSet.iter
    (fun n -> Printf.printf " %s.zv" n)
    deps.fd_dependencies ;
  Printf.printf "\n" ;
  (* Handle dependencies for .v files. *)
  Printf.printf "%s.v:" basename ;
  CompUnitSet.iter
    (fun n -> Printf.printf " %s.v" n)
    deps.fd_dependencies ;
  Printf.printf "\n" ;
  (* Handle dependencies for .cmi files. *)
  Printf.printf "%s.cmi:" basename ;
  CompUnitSet.iter
    (fun n -> Printf.printf " %s.cmi" n)
    deps.fd_dependencies ;
  Printf.printf "\n" ;
  (* Handle dependencies for .cmo files. *)
  Printf.printf "%s.cmo:" basename ;
  CompUnitSet.iter
    (fun n -> Printf.printf " %s.cmo" n)
    deps.fd_dependencies ;
  Printf.printf "\n" ;
  (* Handle dependencies for .cmx files. *)
  Printf.printf "%s.cmx:" basename ;
  CompUnitSet.iter
    (fun n -> Printf.printf " %s.cmx" n)
    deps.fd_dependencies ;
  Printf.printf "\n"
;;


let main () =
  (* The list of files to process in reverse order for sake of efficiency. *)
  let filenames = ref [] in
  try
    Arg.parse
      [ ]
      (fun n -> filenames := n :: !filenames)
      "Usage: focalizec <files>" ;
    let deps = List.map process_one_file (List.rev !filenames) in
    List.iter make_targets deps ;
    exit 0
  with
    | Sys_error m ->
        Printf.eprintf "System@ error - %s.\n" m ;
        exit (-1) ;
     (* ********************** *)
     (* The ultimate firewall. *)
    | x ->
        Printf.eprintf "Unexpected error: \"%s\".\nPlease report.\n"
          (Printexc.to_string x) ;
        exit (-1)
;;
