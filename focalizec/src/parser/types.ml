(** Types of various identifiers in the abstract syntax tree. *)
type cname = string
     (** Collection name. *) ;;
type sname = string
     (** Species name. *) ;;
type tname = string
     (** Type name. *) ;;
type label_name = string
     (** Label name. *) ;;



(* *********************************************** *)
(*  [Type] : simple_type                           *)
(** [Descr] : Describes the type algebra of Focal.

    [Rem] : Exported opaque outside this module.   *)
(* *********************************************** *)
type simple_type =
  | ST_var of variable_type                   (** Type variable. *)
  | ST_arrow of (simple_type * simple_type)   (** Functionnal type. *)
  | ST_tuple of simple_type list              (** Tuple type. *)
  | ST_construct of
      (** Basic type, possibly with arguments. *)
      (tname * simple_type list)
  | ST_prop           (** Type of propositions. *)
  | ST_sefl_rep       (** Carrier type of the currently analysed species.  *)
  | ST_species_rep of cname   (** Carrier type of a collection. *)
  | ST_species_type of species_type     (** Type of a species. *)



and species_type =
  | SPT_collection_interface of collection_type
  | SPT_species_interface of sname
      (** Interface of a species:
	  It could be the list of its method'n'type'n'bodies, i.e.
	  ((string * simple_type * Parsetree.expr) list) but we don't want
	  a structural unification. That's not because 2 species have the
	  same signature that they have the same semantics.
	  Instead, one will get the type of the species via an environment
	  using the [sname] as key. *)
  | SPT_parametrised_in of (sname * simple_type)
  | SPT_parametrised_is of (cname * collection_type)



and collection_type = cname
    (** Interface of a collection:
	It could be the list of its method'n'types, i.e.
	(string * simple_type) list but we don't want
	a structural unification. That's not because 2 collections have the
	same signature that they have the same semantics.
	Instead, one will get the type of the collection via an environment
	using the [cname] as key. *)



(** Variable of type. Must be repr'ed. *)
and variable_type = {
  mutable vt_level : int ;
  mutable vt_value : variable_type_value
}



(** Value of a type variable. *)
and variable_type_value =
  | VTV_unknown
  | VTV_known of simple_type
;;



(* ********************************************* *)
(*  [Type] : types_scheme                        *)
(** [Descr] : Types scheme, i.e. model of types.

    [Rem] : Exported opaque outside this module. *)
(* ********************************************* *)
type types_scheme = {
  ts_type_parameters : variable_type list ;
  ts_body : simple_type }
;;



exception Conflict of simple_type * simple_type ;;
exception Circularity of simple_type * simple_type ;;
exception Arity_mismatch of (string * int * int) ;;  (* Name, expected arity *)


(* ******************************************************************** *)
(*  [Fun] repr : simple_type -> simple_type                             *)
(** [Descr] : Returns the canonical representation of a type.
              Uncompression is performed only one level each time. The
              day the next levels may be needed, this will be during an
              unification, and [repr] will be called if needed to get a
              deeper canonical representation of the type (i.e. the
              canonical representation of its subterms).

    [Rem] : Not exported outside this module.                           *)
(* ******************************************************************** *)
let rec repr = function
  | ST_var ({ vt_value = VTV_known ty1 } as var) ->
      let val_of_ty1 = repr ty1 in
      var.vt_value <- VTV_known val_of_ty1 ;
      val_of_ty1
  | ty -> ty
;;



let (begin_definition, end_definition, current_binding_level, type_variable) =
  let current_binding_level = ref 0 in
  ((fun () -> incr current_binding_level),
   (fun () -> decr current_binding_level),
   (fun () -> !current_binding_level),
   (fun () ->
     ST_var { vt_level = !current_binding_level ; vt_value = VTV_unknown }))
;;


let type_basic ty_name ty_args = ST_construct (ty_name, ty_args) ;;

let type_int () = type_basic "int" [] ;;

let type_float () = type_basic "float" [] ;;

let type_bool () = type_basic "bool" [] ;;

let type_string () = type_basic "string" [] ;;

let type_char () = type_basic "char" [] ;;

let type_unit () = type_basic "unit" [] ;;

let type_arrow t1 t2 = ST_arrow (t1, t2) ;;

let type_tuple tys = ST_tuple tys ;;

let type_self () = ST_sefl_rep ;;


(* [Rem] : Non exported oustide this module. *)
let rec occur_check var ty =
  let rec test t =
    match repr t with
     | ST_var var' ->
         if var == var' then raise (Circularity (ST_var var, ty))
     | ST_arrow (ty1, ty2) -> test ty1 ; test ty2
     | ST_tuple tys -> List.iter test tys
     | ST_construct (_, args) -> List.iter test args
     | ST_prop | ST_sefl_rep | ST_species_rep _ -> ()
     | ST_species_type species_type ->
	 (begin
	 match species_type with
          | SPT_collection_interface _
          | SPT_parametrised_is (_, _)
	  | SPT_species_interface _ -> ()
	  | SPT_parametrised_in (_, ty) -> test ty
	 end) in
  test ty
 ;;



(* [Rem] : Exported oustide this module. *)
let specialize scheme =
  (* Create, for each generalized variable of the type scheme, a       *)
  (* fresh corresponding one and remind the mapping generalized-fresh. *)
  let instanciated_vars =
    List.map (fun var -> (var, type_variable ())) scheme.ts_type_parameters in
  (* Internal recursive copy of a type replacaing generalized variables. *)
  let rec copy_simple_type ty =
    match repr ty with
     | ST_var var as ty ->
	 (* Check in the mapping if this variable was generalized *)
	 (* and if so replace it by its fresh correspondance.     *)
         (try List.assq var instanciated_vars with Not_found -> ty)
     | ST_arrow (ty1, ty2) ->
         ST_arrow (copy_simple_type ty1, copy_simple_type ty2)
     | ST_tuple tys -> ST_tuple (List.map copy_simple_type tys)
     | ST_construct (name, args) -> ST_construct (name, List.map copy_simple_type args)
     | (ST_prop | ST_sefl_rep | ST_species_rep _) as ty -> ty
     | ST_species_type species_type ->
	 let species_type' =
	   (begin
	   match species_type with
	    | SPT_collection_interface _
	    | SPT_species_interface _
            | SPT_parametrised_is (_, _) -> species_type
	    | SPT_parametrised_in (spec_name, ty) ->
		SPT_parametrised_in (spec_name, (copy_simple_type ty))
	   end) in
	 ST_species_type species_type' in
  (* Now really copy the scheme's body while replacing generalised vars. *)
  copy_simple_type scheme.ts_body
;;



(* [Rem] : Exported oustide this module. *)
let generalize ty =
  (* The list of found generalizable variables. *)
  (* We accumulate inside it by side effect.    *)
  let found_ty_parameters = ref ([] : variable_type list) in
  (* Internal recursive hunt for generalizable variables inside the type. *)
  let rec find_parameters ty =
    match repr ty with
     | ST_var var ->
         if var.vt_level > (current_binding_level ()) &&
            not (List.memq var !found_ty_parameters) then
	   found_ty_parameters := var :: !found_ty_parameters
     | ST_arrow (ty1, ty2) -> find_parameters ty1 ; find_parameters ty2
     | ST_tuple tys -> List.iter find_parameters tys
     | ST_construct (_, args) -> List.iter find_parameters args
     | ST_prop | ST_sefl_rep | ST_species_rep _ -> ()
     | ST_species_type species_type ->
	 (begin
	 match species_type with
	  | SPT_collection_interface _
	  | SPT_parametrised_is (_, _)
	  | SPT_species_interface _ -> ()
	  | SPT_parametrised_in (_, ty) -> find_parameters ty
	 end) in
  find_parameters ty ;
  { ts_type_parameters = !found_ty_parameters ; ts_body = ty }
;;



(* [Rem] : Exported oustide this module. *)
let trivial_scheme ty = { ts_type_parameters = [] ; ts_body = ty } ;;



(* [Rem] : Non exported oustide this module. *)
let rec lowerize_levels max_level ty =
  match repr ty with
   | ST_var var -> if var.vt_level > max_level then var.vt_level <- max_level
   | ST_arrow (ty1, ty2) ->
       lowerize_levels max_level ty1 ;
       lowerize_levels max_level ty2
   | ST_tuple tys -> List.iter (lowerize_levels max_level) tys
   | ST_construct (_, args) -> List.iter (lowerize_levels max_level) args
   | ST_prop | ST_sefl_rep | ST_species_rep _-> ()
   | ST_species_type species_type ->
       (begin
       match species_type with
	| SPT_collection_interface _
	| SPT_parametrised_is (_, _)
	| SPT_species_interface _ -> ()
	| SPT_parametrised_in (_, ty) -> lowerize_levels max_level ty
       end)
;;




let rec unify ty1 ty2 =
  let val_of_ty1 = repr ty1 in
  let val_of_ty2 = repr ty2 in
  if val_of_ty1 == val_of_ty2 then ()
  else
    match (val_of_ty1, val_of_ty2) with
     | ((ST_var var), ty) ->
         occur_check var ty ;
         lowerize_levels var.vt_level ty ;
         var.vt_value <- VTV_known ty
     | (ty, (ST_var var)) ->
         occur_check var ty ;
         lowerize_levels var.vt_level ty ;
         var.vt_value <- VTV_known ty
     | (ST_arrow (arg1, res1), ST_arrow (arg2, res2)) ->
         unify arg1 arg2 ;
         unify res1 res2
     | ((ST_tuple tys1), (ST_tuple tys2)) ->
	 (begin
         try List.iter2 unify tys1 tys2
	 with Invalid_argument "List.iter2" ->
           (* In fact, that's an arity mismatch on the tuple. *)
           raise (Conflict (val_of_ty1, val_of_ty2))
         end)
     | (ST_construct (name, args), ST_construct (name', args')) ->
         (begin
         if name <> name' then raise (Conflict (val_of_ty1, val_of_ty2)) ;
         try List.iter2 unify args args'
         with Invalid_argument "List.iter2" ->
           (* In fact, that's an arity mismatch. *)
           raise
	     (Arity_mismatch (name, (List.length args), (List.length args')))
         end)
     | (ST_prop, ST_prop) -> ()
     | (ST_sefl_rep, _) | (_, ST_sefl_rep) -> failwith "todo0"
     | ((ST_species_rep _), _) | (_, (ST_species_rep _)) -> failwith "todo1"
     | ((ST_species_type spety1), (ST_species_type spety2)) ->
	 unify_species_types spety1 spety2
     | (_, _) -> raise (Conflict (val_of_ty1, val_of_ty2))



(* [Rem] : Non exported oustide this module. *)
and unify_species_types spety1 spety2 =
  failwith "todo2"
;;
