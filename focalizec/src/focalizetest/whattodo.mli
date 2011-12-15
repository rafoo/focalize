
(** {6 Module which specify what to do } *)

type typefun =
| Toplevel of string
| Species of string
| Nothing;;
(* TODO revoir �a *)

exception Species_not_defined
exception Property_not_defined

val set_size_value_test : int -> unit
(** [set_size_value_test i] sets the size of random value the user wants to
generate to [i]. *)

val get_size_value_test : unit -> int
(** [get_size_value_test ()] returns the size of random value the user wants to
generate. *)

(*
val set_species_test : Own_expr.species_test -> unit
(** [set_species_test spec] sets the species and effectives parameters, the
user wants to test, to [spec]. *)
*)

(*
val get_species_test : unit -> Own_expr.species_test
(** [get_species_test ()] returns the species and effectives parameters, the
user wants to test. *)
*)

val set_property_test : string list -> unit
(** [set_property_test prop_l] sets the list of properties the user wants to
use to [prop_l] *)

val get_property_test : unit -> string list
(** [get_property_test ()] returns the list of properties the user wants to use
to test. *)

(*
val get_species_string : unit -> string
(** get string version of the species to test. *)
*)

val externfun : typefun option -> typefun
(* TODO revoir ça *)

val set_file_output : string -> unit
(** [set_file_output fic] sets the name of file the user wants to
generate to [fic]. It can be a name with or without .foc suffix. *)

val get_file_output_foc : unit -> string
(** [get_file_output_foc ()] returns the .foc filename the user wants to
generate. *)

val get_file_output_fml : unit -> string
(** [get_file_output_fml ()] returns the .fml filename the user wants to
generate. *)

val get_file_output_xml : unit -> string
(** [get_file_output_fml ()] returns the .xml filename that will be generated.
*)

val get_file_output_prolog : string -> string

val get_output_module : unit -> string
(** [get_output_module ()] returns the name of the module generated by
focaltest. It is usually the name of the filename without extensions *)

val set_number_of_test : int -> unit
(** [set_number_of_test i] sets the numbers a test case the user wants to
generate to [i]. *)

val get_number_of_test : unit -> int
(** [get_number_of_test ()] returns the numbers a test case the user wants to
generate. *)

val set_use_report : string -> unit
(** [set_use_report s] sets the name of the report reinjected for non regression
test. *)

val get_use_report : unit -> string option
(** [get_use_report s] gets the name of the report reinjected for non regression
test. *)

val set_mcdc_number : int -> unit
(** [set_mcdc_number n] sets the number of time we want to apply MC/DC to the
precondition. For n = 0, don't apply MC/DC. *)

val get_mcdc_number : unit -> int
(** [get_mcdc_number ()] gets the number of time we want to apply MC/DC to the
precondition. *)

val set_int_size : int -> unit
(** [set_int_size] sets the size of a random integer. The integer is \[- n/2;(n/2 - 1)\]  *)

val get_int_size : unit -> int
(** [get_int_size ()] returns the size of random generated int *)

val set_use_prolog : bool -> unit;;
(** [get_use_prolog ()]
Do we use prolog for searching for test case ?
*)

val get_use_prolog : unit -> bool;;
(** [get_use_prolog ()]
Do we use prolog for searching for test case ?
*)

val set_prolog_path : string -> unit;;
(** [get_prolog_path s]
Set the prolog directory to [s].
*)

val get_prolog_path : unit -> string;;
(** [get_prolog_path ()]
Get the prolog directory.
*)

val set_prolog_opt : string -> unit;;
(** [get_prolog_opt o]
Set the prolog option to [o].
*)

val get_prolog_opt : unit -> string;;
(** [get_prolog_opt ()]
Get the prolog option.
*)

val set_seq : unit -> unit 
(** Sets the simulation of sequence of instruction to the function seq :

[e1; e2] is transform to [seq(e2,e1)].

This can issue a stack overflow. *) 

val set_let : unit -> unit
(** Sets the simulation of sequence of instruction to the function let method :

[e1; e2] is transform to let unsused = e1 in e2.

This issue some {e unused variable} warning in the .ml file generated from
the .foc file. {e This is the method used by default}. *) 

val set_verbose_mode : bool -> unit;;
(** [set_verbose_mode b] set the program in verbose mode. *)

val print_verbose : string -> unit;;
(** [print_verbose s] prints [s] on stdout if and only if the program is in
verbose mode. *)

(* ***** *)

val use_seq_function : unit -> bool
(** Returns [true] if the user has choice to use the seq function method to
simulate sequence of instruction *)

val set_input_lexbuf : Lexing.lexbuf option -> unit
(** The variable [input_lexbuf] contains temporarily the lexing buffer when parsing an
expression. It is used for generating error message. This function set the value
of lexbuf. *)

val get_input_lexbuf : unit -> Lexing.lexbuf option
(** The function get the value of [lexbuf]. *)

val get_prolog_stat_file : unit -> string option

val set_prolog_stat_file : string option -> unit

val set_globalstk : int -> unit
val get_globalstk : unit -> int

val set_localstk : int -> unit
val get_localstk : unit -> int

val set_choicestk : int -> unit
val get_choicestk : unit -> int

val set_trailstk : int -> unit
val get_trailstk : unit -> int

val set_prologmax : int -> unit
val get_prologmax : unit -> int


val add_open : string -> unit;;
val get_open : unit -> string list;;

