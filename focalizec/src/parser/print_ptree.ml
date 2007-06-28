let pp_position ppf pos =
  Format.fprintf ppf "{ %s ;@ %d ;@ %d ;@ %d }"
    pos.Lexing.pos_fname pos.Lexing.pos_lnum
    pos.Lexing.pos_bol pos.Lexing.pos_cnum
;;



let pp_location ppf loc =
  Format.fprintf ppf "{ %a ;@ %a }"
    pp_position loc.Parsetree.l_beg pp_position loc.Parsetree.l_end
;;



let pp_vname ppf = function
  | Parsetree.Vlident s -> Format.fprintf ppf "Vlident %s" s
  | Parsetree.Vuident s -> Format.fprintf ppf "Vuident %s" s
  | Parsetree.Vpident s -> Format.fprintf ppf "Vpident %s" s
  | Parsetree.Viident s -> Format.fprintf ppf "Viident %s" s
  | Parsetree.Vqident s -> Format.fprintf ppf "Vqident %s" s
;;
let pp_vnames ppf = Ast_types.pp_generic_list pp_vname ppf ;;


let pp_node_label ppf (i, s) = Format.fprintf ppf "(%d,@ %s)" i s ;;
let pp_node_labels ppf = Ast_types.pp_generic_list pp_node_label ppf ;;



let pp_generic_ast desc_printer_fct ppf g_ast =
  Format.fprintf ppf "%a@\n%a"
    pp_location g_ast.Parsetree.ast_loc
    desc_printer_fct g_ast.Parsetree.ast_desc
;;



let pp_ident_desc ppf = function
  | Parsetree.I_local vname ->
      Format.fprintf ppf "I_local@ (%a)" pp_vname vname
  | Parsetree.I_global (fname_opt, vname) ->
      let fname =
	(match fname_opt with None -> "None" | Some n -> "Some (" ^ n ^ ")") in
      Format.fprintf ppf "I_global@ (%s,@ %a)" fname pp_vname vname
  | Parsetree.I_method (cname_opt, vname) ->
      let cname =
	(match cname_opt with None -> "None" | Some n -> "Some (" ^ n ^ ")") in
      Format.fprintf ppf "I_method@ (%s,@ %a)" cname pp_vname vname
;;
let pp_ident ppf = pp_generic_ast pp_ident_desc ppf ;;
let pp_idents ppf = Ast_types.pp_generic_list pp_ident ppf ;;



let rec pp_rep_type_def_desc ppf = function
  | Parsetree.RTE_ident ident ->
      Format.fprintf ppf "RTE_ident@ (%a)" pp_ident ident
  | Parsetree.RTE_fun (rtd1, rtd2) ->
      Format.fprintf ppf "RTE_fun@ (%a,@ %a)"
	pp_rep_type_def rtd1 pp_rep_type_def rtd2
  | Parsetree.RTE_app (ident, rtds) ->
      Format.fprintf ppf "RTE_app@ (%a,@ [%a])"
	pp_ident ident pp_rep_type_defs rtds
  | Parsetree.RTE_prod (rtd1, rtd2) ->
      Format.fprintf ppf "RTE_prod@ (%a,@ %a)"
	pp_rep_type_def rtd1 pp_rep_type_def rtd2
  | Parsetree.RTE_paren rtd ->
      Format.fprintf ppf "RTE_paren@ (%a)" pp_rep_type_def rtd
and pp_rep_type_defs ppf = Ast_types.pp_generic_list pp_rep_type_def ppf
and pp_rep_type_def ppf = pp_generic_ast pp_rep_type_def_desc ppf ;;



let rec pp_type_expr_desc ppf = function
  | Parsetree.TE_ident ident ->
      Format.fprintf ppf "TE_ident@ (%a)" pp_ident ident
  | Parsetree.TE_fun (te1, te2) ->
      Format.fprintf ppf "TE_fun@ (%a,@ %a)" pp_type_expr te1 pp_type_expr te2
  | Parsetree.TE_app (ident, tes) ->
      Format.fprintf ppf "TE_app@ (%a,@ %a)"
	pp_ident ident pp_type_exprs tes
  | Parsetree.TE_prod (te1, te2) ->
      Format.fprintf ppf "TE_prod@ (%a,@ %a)" pp_type_expr te1 pp_type_expr te2
  | Parsetree.TE_self -> Format.fprintf ppf "TE_self"
  | Parsetree.TE_prop -> Format.fprintf ppf "TE_prop"
  | Parsetree.TE_paren te -> Format.fprintf ppf "TE_paren@ (%a)" pp_type_expr te
and pp_type_exprs ppf = Ast_types.pp_generic_list pp_type_expr ppf
and pp_type_expr ppf = pp_generic_ast pp_type_expr_desc ppf ;;



let pp_constant_desc ppf = function
  | Parsetree.C_int s -> Format.fprintf ppf "C_int@ (%s)" s
  | Parsetree.C_float s -> Format.fprintf ppf "C_float@ (%s)" s
  | Parsetree.C_bool s -> Format.fprintf ppf "C_bool@ (%s)" s
  | Parsetree.C_string s -> Format.fprintf ppf "C_string@ (%s)" s
  | Parsetree.C_char c ->
      let tmp_s = " " in
      tmp_s.[0] <- c ;
      Format.fprintf ppf "C_char@ (%s)" tmp_s
;;
let pp_constant = pp_generic_ast pp_constant_desc
;;



let pp_rec_flag ppf = function
  | Parsetree.RF_no_rec -> Format.fprintf ppf "RF_no_rec"
  | Parsetree.RF_rec -> Format.fprintf ppf "RF_rec"
;;



let pp_log_flag ppf = function
  | Parsetree.LF_no_log -> Format.fprintf ppf "LF_no_log"
  | Parsetree.LF_log -> Format.fprintf ppf "LF_log"
;;



let pp_loc_flag ppf = function
  | Parsetree.LF_no_loc -> Format.fprintf ppf "LF_no_loc"
  | Parsetree.LF_loc -> Format.fprintf ppf "LF_loc"
;;



let rec pp_pat_desc ppf = function
  | Parsetree.P_const cst -> Format.fprintf ppf "P_const@ (%a)" pp_constant cst
  | Parsetree.P_var vname -> Format.fprintf ppf "P_var@ (%a)" pp_vname vname
  | Parsetree.P_as (pat, vname) ->
      Format.fprintf ppf "P_as@ (%a,@ %a)" pp_pattern pat pp_vname vname
  | Parsetree.P_wild -> Format.fprintf ppf "P_wild"
  | Parsetree.P_app (ident, pats) ->
      Format.fprintf ppf "P_app@ (%a,@ %a)" pp_ident ident pp_patterns pats
  | Parsetree.P_record lab_pat_lst ->
      Format.fprintf ppf "P_record@ ([%a])"
	(Ast_types.pp_generic_list
	   (fun local_ppf (label, pat) ->
	     Format.fprintf local_ppf "(%s,@ %a)" label pp_pattern pat))
	lab_pat_lst
  | Parsetree.P_tuple pats ->
      Format.fprintf ppf "P_tuple@ ([%a])" pp_patterns pats
  | Parsetree.P_paren pat -> Format.fprintf ppf "P_paren@ (%a)" pp_pattern pat
and pp_patterns ppf = Ast_types.pp_generic_list pp_pattern ppf
and pp_pattern ppf = pp_generic_ast pp_pat_desc ppf ;;



let pp_external_language ppf = function
  | Parsetree.EL_Caml -> Format.fprintf ppf "EL_Caml"
  | Parsetree.EL_Coq -> Format.fprintf ppf "EL_Coq"
  | Parsetree.EL_external s -> Format.fprintf ppf "EL_external@ (%s)" s
;;



let rec pp_external_def_desc ppf = function
  | Parsetree.ED_type edb ->
      Format.fprintf ppf "ED_type@ (%a)" pp_external_def_body edb
  | Parsetree.ED_value edb ->
      Format.fprintf ppf "ED_value@ (%a)" pp_external_def_body edb
and pp_external_def ppf = pp_generic_ast pp_external_def_desc ppf



and pp_external_def_body_desc ppf body =
  Format.fprintf ppf "{ %a ;@ %a }"
    pp_vname body.Parsetree.ed_name pp_external_expr body.Parsetree.ed_body
and pp_external_def_body ppf = pp_generic_ast pp_external_def_body_desc ppf



and external_expr_desc ppf lst =
  Format.fprintf ppf "[@ %a@ ]"
    (Ast_types.pp_generic_list
       (fun local_ppf (ext_lang, ext_expr) ->
	 Format.fprintf local_ppf "(%a,@ %a)"
	   pp_external_language ext_lang pp_external_expression ext_expr))
    lst
and pp_external_expr ppf = pp_generic_ast external_expr_desc ppf



and pp_external_expression ppf eexpr = Format.fprintf ppf "%s" eexpr ;;



let rec pp_species_def_desc ppf def =
  Format.fprintf ppf
    "{@ %s ;@ [@ %a@ ] ;@ [@ %a@ ] ; [@ %a@ ] }"
    def.Parsetree.sd_name
    (Ast_types.pp_generic_list
       (fun local_ppf (vname, species_param_type) ->
	 Format.fprintf local_ppf "(%a,@ %a)"
	   pp_vname vname pp_species_param_type species_param_type))
    def.Parsetree.sd_params
    pp_species_exprs def.Parsetree.sd_inherits.Parsetree.ast_desc
    pp_species_fields def.Parsetree.sd_fields
and pp_species_def ppf = pp_generic_ast pp_species_def_desc ppf



and pp_species_param_type_desc ppf = function
  | Parsetree.SPT_in ident ->
      Format.fprintf ppf "SPT_in@ (%a)" pp_ident ident
  | Parsetree.SPT_is species_expr ->
      Format.fprintf ppf "SPT_is@ (%a)" pp_species_expr species_expr
and pp_species_param_type ppf = pp_generic_ast pp_species_param_type_desc ppf



and pp_species_expr_desc ppf sed =
  Format.fprintf ppf "{@ %a ;@ %a }"
    pp_ident sed.Parsetree.se_name pp_species_params sed.Parsetree.se_params
and pp_species_exprs ppf = Ast_types.pp_generic_list pp_species_expr ppf
and pp_species_expr ppf = pp_generic_ast pp_species_expr_desc ppf



and pp_species_param_desc ppf = function
  | Parsetree.SP expr -> Format.fprintf ppf "SP@ (%a)" pp_expr expr
and pp_species_params ppf = Ast_types.pp_generic_list pp_species_param ppf
and pp_species_param ppf = pp_generic_ast pp_species_param_desc ppf



and pp_sig_def_desc ppf sdd =
  Format.fprintf ppf "{@ %a ;@ %a }"
    pp_ident sdd.Parsetree.sig_name pp_type_expr sdd.Parsetree.sig_type
and pp_sig_def ppf = pp_generic_ast pp_sig_def_desc ppf



and pp_proof_def_desc ppf pdd =
  Format.fprintf ppf "{@ %a ;@ %a }"
    pp_ident pdd.Parsetree.pd_name pp_proof pdd.Parsetree.pd_proof
and pp_proof_def ppf = pp_generic_ast pp_proof_def_desc ppf



and pp_property_def_desc ppf pdd =
  Format.fprintf ppf "{@ %a ;@ %a }"
    pp_ident pdd.Parsetree.prd_name pp_prop pdd.Parsetree.prd_prop
and pp_property_def ppf = pp_generic_ast pp_property_def_desc ppf



and pp_species_field_desc ppf = function
  | Parsetree.SF_rep rep_type_def ->
      Format.fprintf ppf "SF_rep@ (%a)" pp_rep_type_def rep_type_def
  | Parsetree.SF_sig sig_def ->
      Format.fprintf ppf "SF_sig@ (%a)" pp_sig_def sig_def
  | Parsetree.SF_let let_def ->
      Format.fprintf ppf "SF_let@ (%a)" pp_let_def let_def
  | Parsetree.SF_property property_def ->
      Format.fprintf ppf "SF_property@ (%a)" pp_property_def property_def
  | Parsetree.SF_theorem theorem_def ->
      Format.fprintf ppf "SF_theorem@ (%a)" pp_theorem_def theorem_def
  | Parsetree.SF_proof proof_def ->
      Format.fprintf ppf "SF_proof@ (%a)" pp_proof_def proof_def
and pp_species_fields ppf = Ast_types.pp_generic_list pp_species_field ppf
and pp_species_field ppf = pp_generic_ast pp_species_field_desc ppf



and pp_let_def_desc ppf ldd =
  Format.fprintf ppf "{@ %a ;@ %a ;@ %a ;@ [@ %a@ ] }"
    pp_rec_flag ldd.Parsetree.ld_rec
    pp_log_flag ldd.Parsetree.ld_log
    pp_loc_flag ldd.Parsetree.ld_loc
    pp_bindings ldd.Parsetree.ld_bindings
and pp_let_def ppf = pp_generic_ast pp_let_def_desc ppf



and pp_binding_desc ppf bd =
  Format.fprintf ppf "{@ %a ;@ [@ %a@ ] @ %a }"
    pp_ident bd.Parsetree.b_name
    (Ast_types.pp_generic_list
       (fun local_ppf (ident, ty_expr_opt) ->
	 Format.fprintf local_ppf "(%a,@ %a)"
	   pp_ident ident
	   (Ast_types.pp_generic_option pp_type_expr) ty_expr_opt))
    bd.Parsetree.b_params
    pp_expr bd.Parsetree.b_body
and pp_bindings ppf = Ast_types.pp_generic_list pp_binding ppf
and pp_binding ppf = pp_generic_ast pp_binding_desc ppf



and pp_theorem_def_desc ppf tdd =
  Format.fprintf ppf "{@ %a ;@ %a ;@ %a ;@ %a }"
    pp_ident tdd.Parsetree.th_name
    pp_loc_flag tdd.Parsetree.th_loc
    pp_prop tdd.Parsetree.th_stmt
    pp_proof tdd.Parsetree.th_proof
and pp_theorem_def ppf = pp_generic_ast pp_theorem_def_desc ppf



and pp_fact_desc ppf = function
  | Parsetree.F_def idents ->
      Format.fprintf ppf "F_def@ ([@ %a@ ])" pp_idents idents
  | Parsetree.F_property idents ->
      Format.fprintf ppf "F_property@ ([@ %a@ ])" pp_idents idents
  | Parsetree.F_hypothesis vnames ->
      Format.fprintf ppf "F_hypothesis@ ([@ %a@ ])" pp_vnames vnames
  | Parsetree.F_node node_labels ->
      Format.fprintf ppf "F_node@ ([@ %a@ ])" pp_node_labels node_labels
and pp_facts ppf = Ast_types.pp_generic_list pp_fact ppf
and pp_fact ppf = pp_generic_ast pp_fact_desc ppf



and pp_proof_desc ppf = function
  | Parsetree.Pf_assumed -> Format.fprintf ppf "Pf_assumed"
  | Parsetree.Pf_auto facts ->
      Format.fprintf ppf "Pf_auto@ ([@ %a@ ])" pp_facts facts
  | Parsetree.Pf_coq s -> Format.fprintf ppf "Pf_coq@ (%s)" s
  | Parsetree.Pf_node proof_nodes ->
      Format.fprintf ppf "Pf_node@ ([@ %a@ ])" pp_proof_nodes proof_nodes
and pp_proof ppf = pp_generic_ast pp_proof_desc ppf



and pp_proof_node_desc ppf = function
  | Parsetree.PN_sub (node_label, stmt, proof) ->
      Format.fprintf ppf "PN_sub@ (%a,@ %a,@ %a)"
	pp_node_label node_label pp_statement stmt pp_proof proof
  | Parsetree.PN_qed (node_label, proof) ->
      Format.fprintf ppf "PN_qed@ (%a,@ %a)"
	pp_node_label node_label pp_proof proof
and pp_proof_nodes ppf = Ast_types.pp_generic_list proof_node ppf
and proof_node ppf = pp_generic_ast pp_proof_node_desc ppf



and pp_statement_desc ppf stmt =
  Format.fprintf ppf "{@ [@ %a@ ] ;@ %a }"
    pp_hyps stmt.Parsetree.s_hyps
    (Ast_types.pp_generic_option pp_prop) stmt.Parsetree.s_concl
and pp_statement ppf = pp_generic_ast pp_statement_desc ppf



and pp_hyp_desc ppf = function
  | Parsetree.H_var (vname, te) ->
      Format.fprintf ppf "H_var@ (%a,@ %a)" pp_vname vname pp_type_expr te
  | Parsetree.H_hyp (vname, prop) ->
      Format.fprintf ppf "H_hyp@ (%a,@ %a)" pp_vname vname pp_prop prop
  | Parsetree.H_not (vname, expr) ->
      Format.fprintf ppf "H_not@ (%a,@ %a)" pp_vname vname pp_expr expr
and pp_hyps ppf = Ast_types.pp_generic_list pp_hyp ppf
and pp_hyp ppf = pp_generic_ast pp_hyp_desc ppf



and pp_prop_desc ppf = function
  | Parsetree.Pr_forall (vnames, type_expr_opt, prop) ->
      Format.fprintf ppf "Pr_forall@ ([@ %a@ ],@ %a,@ %a)"
	pp_vnames vnames
	(Ast_types.pp_generic_option pp_type_expr) type_expr_opt
	pp_prop prop
  | Parsetree.Pr_exists (vnames, type_expr_opt, prop) ->
      Format.fprintf ppf "Pr_exists@ ([@ %a@ ],@ %a,@ %a)"
	pp_vnames vnames
	(Ast_types.pp_generic_option pp_type_expr) type_expr_opt
	pp_prop prop
  | Parsetree.Pr_imply (p1, p2) ->
      Format.fprintf ppf "Pr_imply@ (%a,@ %a)" pp_prop p1 pp_prop p2
  | Parsetree.Pr_or (p1, p2) ->
      Format.fprintf ppf "Pr_or@ (%a,@ %a)" pp_prop p1 pp_prop p2
  | Parsetree.Pr_and (p1, p2) ->
      Format.fprintf ppf "Pr_and@ (%a,@ %a)" pp_prop p1 pp_prop p2
  | Parsetree.Pr_equiv (p1, p2) ->
      Format.fprintf ppf "Pr_equiv@ (%a,@ %a)" pp_prop p1 pp_prop p2
  | Parsetree.Pr_not p -> Format.fprintf ppf "Pr_not@ (%a)" pp_prop p
  | Parsetree.Pr_expr e -> Format.fprintf ppf "Pr_expr@ (%a)" pp_expr e
  | Parsetree.Pr_paren p -> Format.fprintf ppf "Pr_paren@ (%a)" pp_prop p
and pp_prop ppf = pp_generic_ast pp_prop_desc ppf



and pp_expr_desc ppf = function
  | Parsetree.E_const cst -> Format.fprintf ppf "E_const@ (%a)" pp_constant cst
  | Parsetree.E_fun (vnames, expr) ->
      Format.fprintf ppf "E_fun@ ([@ %a@ ],@ %a)"
	pp_vnames vnames pp_expr expr
  | Parsetree.E_var id -> Format.fprintf ppf "E_var@ (%a)" pp_ident id
  | Parsetree.E_app (expr, exprs) ->
      Format.fprintf ppf "E_app@ (%a,@ [@ %a@ ])" pp_expr expr pp_exprs exprs
  | Parsetree.E_constr (expr, exprs) ->
      Format.fprintf ppf "E_constr@ (%a,@ [@ %a@ ])" pp_expr expr pp_exprs exprs
  | Parsetree.E_match (expr, pat_exprs) ->
      Format.fprintf ppf "E_match@ (%a,@ [@ %a@ ])"
	pp_expr expr
	(Ast_types.pp_generic_list
	   (fun local_ppf (pat, e) ->
	     Format.fprintf local_ppf "(%a,@ %a)" pp_pattern pat pp_expr e))
	pat_exprs
  | Parsetree.E_if (expr1, expr2, expr3) ->
      Format.fprintf ppf "E_if@ (%a,@ %a,@ %a)"
	pp_expr expr1 pp_expr expr2 pp_expr expr3
  | Parsetree.E_let (let_def, expr) ->
      Format.fprintf ppf "E_let@ (%a,@ %a)" pp_let_def let_def pp_expr expr
  | Parsetree.E_record label_exprs ->
      Format.fprintf ppf "E_record@ ([@ %a@ ])"
	(Ast_types.pp_generic_list
	   (fun local_ppf (lab_name, e) ->
	     Format.fprintf local_ppf "(%s,@ %a)" lab_name pp_expr e))
	label_exprs
  | Parsetree.E_record_access (expr, label_name) ->
      Format.fprintf ppf "E_record_access@ (%a,@ %s)" pp_expr expr label_name
  | Parsetree.E_record_with (expr, label_exprs) ->
      Format.fprintf ppf "E_record_with@ (%a,@ [@ %a@ ])"
	pp_expr expr
	(Ast_types.pp_generic_list
	   (fun local_ppf (lab_name, e) ->
	     Format.fprintf local_ppf "(%s,@ %a)" lab_name pp_expr e))
	label_exprs
  | Parsetree.E_tuple exprs ->
      Format.fprintf ppf "E_tuple@ ([@ %a@ ])" pp_exprs exprs
  | Parsetree.E_external external_expr ->
      Format.fprintf ppf "E_external@ (%a)" pp_external_expr external_expr
  | Parsetree.E_paren expr -> Format.fprintf ppf "E_paren@ (%a)" pp_expr expr
and pp_exprs ppf = Ast_types.pp_generic_list pp_expr ppf
and pp_expr ppf = pp_generic_ast pp_expr_desc ppf
;;



let pp_coll_def_desc ppf cdd =
  Format.fprintf ppf "{@ %s ;@ %a }"
    cdd.Parsetree.cd_name pp_species_expr cdd.Parsetree.cd_body
;;
let pp_coll_def ppf = pp_generic_ast pp_coll_def_desc ppf ;;



let pp_tmp_TD_union ppf l =
  Format.fprintf ppf "TD_union ([@ %a@ ])"
    (Ast_types.pp_generic_list
       (fun local_ppf (constr_name, type_exprs) ->
	 Format.fprintf local_ppf "(%a,@ [@ %a@ ])"
	   pp_vname constr_name pp_type_exprs type_exprs))
    l
;;
	   


let rec pp_type_def_desc ppf td =
  Format.fprintf ppf "{@ %s ;@ [@ %a@ ] ;@ %a }"
    td.Parsetree.td_name
    (Ast_types.pp_generic_list
       (fun local_ppf s -> Format.fprintf local_ppf "%s" s))
    td.Parsetree.td_params
    pp_type_body td.Parsetree.td_body
and pp_type_def ppf = pp_generic_ast pp_type_def_desc ppf



and pp_type_body_desc ppf = function
  | Parsetree.TD_alias te -> Format.fprintf ppf "TD_alias@ (%a)" pp_type_expr te
  | Parsetree.TD_union l -> Format.fprintf ppf "%a" pp_tmp_TD_union l
  | Parsetree.TD_record lab_exprs ->
      Format.fprintf ppf "TD_record@ ([@ %a@ ])"
	(Ast_types.pp_generic_list
	   (fun local_ppf (lab, e) ->
	     Format.fprintf local_ppf "(%s, %a)" lab pp_type_expr e))
	lab_exprs
and pp_type_body ppf = pp_generic_ast pp_type_body_desc ppf
;;



let pp_phrase_desc ppf = function
  | Parsetree.Ph_external external_def ->
      Format.fprintf ppf "Ph_external@ (%a)" pp_external_def external_def
  | Parsetree.Ph_use fname -> Format.fprintf ppf "Ph_use@ (%s)" fname
  | Parsetree.Ph_open fname -> Format.fprintf ppf "Ph_open@ (%s)" fname
  | Parsetree.Ph_species species_def ->
      Format.fprintf ppf "Ph_species@ (%a)" pp_species_def species_def
  | Parsetree.Ph_coll coll_def ->
      Format.fprintf ppf "Ph_coll@ (%a)" pp_coll_def coll_def
  | Parsetree.Ph_type type_def ->
      Format.fprintf ppf "Ph_type@ (%a)" pp_type_def type_def
  | Parsetree.Ph_let let_def ->
      Format.fprintf ppf "Ph_let@ (%a)" pp_let_def let_def
  | Parsetree.Ph_theorem theorem_def ->
      Format.fprintf ppf "Ph_theorem@ (%a)" pp_theorem_def theorem_def
  | Parsetree.Ph_expr expr -> Format.fprintf ppf "Ph_expr@ (%a)" pp_expr expr
;;
let pp_phrase ppf = pp_generic_ast pp_phrase_desc ppf ;;
let pp_phrases ppf = Ast_types.pp_generic_list pp_phrase ppf ;;



let pp_file_desc ppf = function
  | Parsetree.File phrases ->
      Format.fprintf ppf "File@ ([@ %a@ ])" pp_phrases phrases
;;
let pp_file ppf = pp_generic_ast pp_file_desc ppf ;;

