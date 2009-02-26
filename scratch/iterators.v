Require Import zenon.
Require Import zenon_induct.
Require Import zenon_focal.
Require Export Bool.
Require Export ZArith.
Open Scope Z_scope.
Require Export Reals.
Require Export Ascii.
Require Export String.
Require Export List.
Require Export Recdef.
Require Export coq_builtins.

Require basics.
Require sets.
Require sets.
Require basics.
Require constants.
Require constants.
Require integers.
Require integers.
Module Binop.
  Record Binop (S_T : Set) (_p_S_equal : S_T -> S_T -> basics.bool__t)
    : Type :=
    mk_record {
    rf_T :> Set ;
    (* From species iterators#Binop. *)
    rf_binop : S_T -> S_T -> S_T ;
    (* From species iterators#Binop. *)
    rf_binop_substitution_rule :
      forall x_1  x_2  y_1  y_2 : S_T,
        Is_true ((_p_S_equal x_1 x_2)) ->
          Is_true ((_p_S_equal y_1 y_2)) ->
            Is_true ((_p_S_equal (rf_binop x_1 y_1) (rf_binop x_2 y_2))) ;
    (* From species basics#Basic_object. *)
    rf_parse : basics.string__t -> rf_T ;
    (* From species basics#Basic_object. *)
    rf_print : rf_T -> basics.string__t
    }.
  
  
End Binop.

Module Iteration.
  Record Iteration (Nat_T : Set) (S_T : Set) (F_binary_T : Set) (_p_zero_zero :
                                                                 S_T) (_p_Nat_start : Nat_T)
    (_p_Nat_successor : Nat_T -> Nat_T)
    (_p_S_equal : S_T -> S_T -> basics.bool__t)
    (_p_F_binary_binop : S_T -> S_T -> S_T) : Type :=
    mk_record {
    rf_T :> Set ;
    (* From species iterators#Iteration. *)
    rf_iterate : S_T -> Nat_T -> S_T ;
    (* From species iterators#Iteration. *)
    rf_iterate_spec_base :
      forall x : S_T,
        Is_true ((_p_S_equal (rf_iterate x _p_Nat_start) _p_zero_zero)) ;
    (* From species iterators#Iteration. *)
    rf_iterate_spec_ind :
      forall x : S_T,
        forall n : Nat_T,
          Is_true ((_p_S_equal (rf_iterate x (_p_Nat_successor n))
                     (_p_F_binary_binop x (rf_iterate x n))))
    }.
  
  Module Termination_iterate_namespace.
    Section iterate.
      Variable _p_Nat_T : Set.
      Variable _p_S_T : Set.
      Variable _p_Nat_lt : _p_Nat_T -> _p_Nat_T -> basics.bool__t.
      Variable _p_Nat_predecessor : _p_Nat_T -> _p_Nat_T.
      Variable _p_Nat_start : _p_Nat_T.
      Variable _p_Nat_equal : _p_Nat_T -> _p_Nat_T -> basics.bool__t.
      Variable _p_F_binary_binop : _p_S_T -> _p_S_T -> _p_S_T.
      Variable _p_zero_zero : _p_S_T.
      
      
      (* Abstracted termination order. *)
      Variable __term_order :
        (((_p_S_T) * (_p_Nat_T))%type) -> (((_p_S_T) * (_p_Nat_T))%type) -> Prop.
      Variable __term_obl :(forall x : _p_S_T, forall n : _p_Nat_T, ~
        Is_true ((_p_Nat_equal n _p_Nat_start)) -> __term_order
        (x, (_p_Nat_predecessor n)) (x, n))
        /\
         (well_founded __term_order).
      
      Function iterate (__arg: (((_p_S_T) * (_p_Nat_T))%type))
        {wf __term_order __arg}: _p_S_T
        :=
        match __arg with
          | (x,
          n) =>
          if (_p_Nat_equal n _p_Nat_start) then _p_zero_zero
            else (_p_F_binary_binop x (iterate (x, (_p_Nat_predecessor n))))
          end.
        Proof.
          assert (__force_use_p_Nat_T := _p_Nat_T).
          assert (__force_use_p_S_T := _p_S_T).
          assert (__force_use__p_Nat_lt := _p_Nat_lt).
          assert (__force_use__p_Nat_predecessor := _p_Nat_predecessor).
          assert (__force_use__p_Nat_start := _p_Nat_start).
          assert (__force_use__p_Nat_equal := _p_Nat_equal).
          assert (__force_use__p_F_binary_binop := _p_F_binary_binop).
          assert (__force_use__p_zero_zero := _p_zero_zero).
          apply coq_builtins.magic_prove.
          apply coq_builtins.magic_prove.
          Qed.
        Definition Iteration__iterate x  n := iterate (x, n).
**
        End iterate.
      End Termination_iterate_namespace.
    Definition iterate (_p_Nat_T : Set) (_p_S_T : Set) (_p_Nat_lt :
      _p_Nat_T -> _p_Nat_T -> basics.bool__t) (_p_Nat_predecessor :
      _p_Nat_T -> _p_Nat_T) (_p_Nat_start : _p_Nat_T) (_p_Nat_equal :
      _p_Nat_T -> _p_Nat_T -> basics.bool__t) (_p_F_binary_binop :
      _p_S_T -> _p_S_T -> _p_S_T) (_p_zero_zero : _p_S_T) :=
      Termination_iterate_namespace.Iteration__iterate _p_Nat_T _p_S_T
      _p_Nat_lt _p_Nat_predecessor _p_Nat_start _p_Nat_equal
      _p_F_binary_binop _p_zero_zero coq_builtins.magic_order.
    
    (* From species iterators#Iteration. *)
    (* Section for proof of theorem 'iterate_spec_base'. *)
    Section Proof_of_iterate_spec_base.
      Variable _p_Nat_T : Set.
      Variable _p_S_T : Set.
      Variable _p_Nat_lt : _p_Nat_T -> _p_Nat_T -> basics.bool__t.
      Variable _p_Nat_predecessor : _p_Nat_T -> _p_Nat_T.
      Variable _p_Nat_start : _p_Nat_T.
      Variable _p_Nat_equal : _p_Nat_T -> _p_Nat_T -> basics.bool__t.
      Variable _p_Nat_equal_reflexive :
        forall x : _p_Nat_T, Is_true ((_p_Nat_equal x x)).
      Variable _p_S_equal : _p_S_T -> _p_S_T -> basics.bool__t.
      Variable _p_S_equal_reflexive :
        forall x : _p_S_T, Is_true ((_p_S_equal x x)).
      Variable _p_F_binary_binop : _p_S_T -> _p_S_T -> _p_S_T.
      Variable _p_zero_zero : _p_S_T.
      Let abst_iterate := iterate _p_Nat_T _p_S_T _p_Nat_lt
      _p_Nat_predecessor _p_Nat_start _p_Nat_equal _p_F_binary_binop
      _p_zero_zero.
(* File "iterators.fcl", line 58, character 12, line 59, character 37 *)
Theorem for_zenon_iterate_spec_base:(forall x:_p_S_T,(Is_true (
_p_S_equal (abst_iterate x _p_Nat_start) _p_zero_zero))).
Proof.
exact(
(NNPP _ (fun zenon_G=>(zenon_notall _p_S_T (fun x:_p_S_T=>(Is_true (
_p_S_equal (abst_iterate x _p_Nat_start) _p_zero_zero))) (fun(
zenon_Tx_a:_p_S_T) zenon_Ha=>(let zenon_H9:=zenon_Ha in (
zenon_focal_ite_rel_nl (fun zenon_Vf zenon_Vg=>(Is_true (_p_S_equal
zenon_Vf zenon_Vg))) (_p_Nat_equal _p_Nat_start _p_Nat_start)
_p_zero_zero (_p_F_binary_binop zenon_Tx_a (abst_iterate zenon_Tx_a (
_p_Nat_predecessor _p_Nat_start))) _p_zero_zero (fun zenon_H6 zenon_H5=>
(zenon_all _p_S_T (fun x:_p_S_T=>(Is_true (_p_S_equal x x)))
_p_zero_zero (fun zenon_H4=>(zenon_H5 zenon_H4)) _p_S_equal_reflexive))
(fun zenon_H7 zenon_H8=>(zenon_all _p_Nat_T (fun x:_p_Nat_T=>(Is_true (
_p_Nat_equal x x))) _p_Nat_start (fun zenon_H6=>(zenon_H7 zenon_H6))
_p_Nat_equal_reflexive)) zenon_H9))) zenon_G)))).
Qed.

      (* Dummy theorem to enforce Coq abstractions. *)
      Theorem for_zenon_abstracted_iterate_spec_base :
        forall x : _p_S_T,
          Is_true ((_p_S_equal (abst_iterate x _p_Nat_start) _p_zero_zero)).
      assert (__force_use_p_Nat_T := _p_Nat_T).
      assert (__force_use_p_S_T := _p_S_T).
      assert (__force_use__p_Nat_lt := _p_Nat_lt).
      assert (__force_use__p_Nat_predecessor := _p_Nat_predecessor).
      assert (__force_use__p_Nat_start := _p_Nat_start).
      assert (__force_use__p_Nat_equal := _p_Nat_equal).
      assert (__force_use__p_Nat_equal_reflexive := _p_Nat_equal_reflexive).
      assert (__force_use__p_S_equal := _p_S_equal).
      assert (__force_use__p_S_equal_reflexive := _p_S_equal_reflexive).
      assert (__force_use__p_F_binary_binop := _p_F_binary_binop).
      assert (__force_use__p_zero_zero := _p_zero_zero).
      assert (__force_use_abst_iterate := abst_iterate).
      apply for_zenon_iterate_spec_base ;
      auto.
      Qed.
      End Proof_of_iterate_spec_base.
    
    Theorem iterate_spec_base  (_p_Nat_T : Set) (_p_S_T : Set) (_p_Nat_lt :
      _p_Nat_T -> _p_Nat_T -> basics.bool__t) (_p_Nat_predecessor :
      _p_Nat_T -> _p_Nat_T) (_p_Nat_start : _p_Nat_T) (_p_Nat_equal :
      _p_Nat_T -> _p_Nat_T -> basics.bool__t) (_p_Nat_equal_reflexive :
      forall x : _p_Nat_T, Is_true ((_p_Nat_equal x x))) (_p_S_equal :
      _p_S_T -> _p_S_T -> basics.bool__t) (_p_S_equal_reflexive :
      forall x : _p_S_T, Is_true ((_p_S_equal x x))) (_p_F_binary_binop :
      _p_S_T -> _p_S_T -> _p_S_T) (_p_zero_zero : _p_S_T) (abst_iterate :=
      iterate _p_Nat_T _p_S_T _p_Nat_lt _p_Nat_predecessor _p_Nat_start
      _p_Nat_equal _p_F_binary_binop _p_zero_zero):
      forall x : _p_S_T,
        Is_true ((_p_S_equal (abst_iterate x _p_Nat_start) _p_zero_zero)).
    apply for_zenon_abstracted_iterate_spec_base ;
    auto.
    Qed.
    
    (* From species iterators#Iteration. *)
    (* Section for proof of theorem 'iterate_spec_ind'. *)
    Section Proof_of_iterate_spec_ind.
      Variable _p_Nat_T : Set.
      Variable _p_S_T : Set.
      Variable _p_Nat_lt : _p_Nat_T -> _p_Nat_T -> basics.bool__t.
      Variable _p_Nat_predecessor : _p_Nat_T -> _p_Nat_T.
      Variable _p_Nat_start : _p_Nat_T.
      Variable _p_Nat_successor : _p_Nat_T -> _p_Nat_T.
      Variable _p_Nat_equal : _p_Nat_T -> _p_Nat_T -> basics.bool__t.
      Variable _p_Nat_predecessor_reverses_successor :
        forall x  y : _p_Nat_T,
          Is_true ((_p_Nat_equal x (_p_Nat_successor y))) ->
            Is_true ((_p_Nat_equal y (_p_Nat_predecessor x))).
      Variable _p_Nat_successor_is_non_trivial :
        forall n : _p_Nat_T,
          ~Is_true (((_p_Nat_equal (_p_Nat_successor n) _p_Nat_start))).
      Variable _p_Nat_equal_reflexive :
        forall x : _p_Nat_T, Is_true ((_p_Nat_equal x x)).
      Variable _p_Nat_equal_symmetric :
        forall x  y : _p_Nat_T,
          Is_true ((_p_Nat_equal x y)) -> Is_true ((_p_Nat_equal y x)).
      Variable _p_Nat_equal_transitive :
        forall x  y  z : _p_Nat_T,
          Is_true ((_p_Nat_equal x y)) ->
            Is_true ((_p_Nat_equal y z)) -> Is_true ((_p_Nat_equal x z)).
      Variable _p_S_equal : _p_S_T -> _p_S_T -> basics.bool__t.
      Variable _p_S_equal_reflexive :
        forall x : _p_S_T, Is_true ((_p_S_equal x x)).
      Variable _p_S_equal_transitive :
        forall x  y  z : _p_S_T,
          Is_true ((_p_S_equal x y)) ->
            Is_true ((_p_S_equal y z)) -> Is_true ((_p_S_equal x z)).
      Variable _p_F_binary_binop : _p_S_T -> _p_S_T -> _p_S_T.
      Variable _p_zero_zero : _p_S_T.
      Let abst_iterate := iterate _p_Nat_T _p_S_T _p_Nat_lt
      _p_Nat_predecessor _p_Nat_start _p_Nat_equal _p_F_binary_binop
      _p_zero_zero.
      Section __B_1.
        Variable x : _p_S_T.
        Variable n : _p_Nat_T.
        Section __B_1_1.
(* File "iterators.fcl", line 68, character 71, line 72, character 50 *)
Theorem for_zenon___B_1_1_LEMMA:(Is_true (_p_Nat_equal (
_p_Nat_predecessor (_p_Nat_successor n)) n)).
Proof.
exact(
(NNPP _ (fun zenon_G=>(zenon_all _p_Nat_T (fun x:_p_Nat_T=>(forall y
:_p_Nat_T,((Is_true (_p_Nat_equal x (_p_Nat_successor y)))->(Is_true (
_p_Nat_equal y (_p_Nat_predecessor x)))))) (_p_Nat_successor n) (fun
zenon_Hd=>(zenon_all _p_Nat_T (fun y:_p_Nat_T=>((Is_true (_p_Nat_equal (
_p_Nat_successor n) (_p_Nat_successor y)))->(Is_true (_p_Nat_equal y (
_p_Nat_predecessor (_p_Nat_successor n)))))) n (fun zenon_Hc=>(
zenon_imply _ _ (fun zenon_Hb=>(zenon_all _p_Nat_T (fun x:_p_Nat_T=>(
Is_true (_p_Nat_equal x x))) (_p_Nat_successor n) (fun zenon_Ha=>(
zenon_Hb zenon_Ha)) _p_Nat_equal_reflexive)) (fun zenon_H6=>(zenon_all
_p_Nat_T (fun x:_p_Nat_T=>(forall y:_p_Nat_T,((Is_true (_p_Nat_equal x
y))->(Is_true (_p_Nat_equal y x))))) n (fun zenon_H9=>(zenon_all
_p_Nat_T (fun y:_p_Nat_T=>((Is_true (_p_Nat_equal n y))->(Is_true (
_p_Nat_equal y n)))) (_p_Nat_predecessor (_p_Nat_successor n)) (fun
zenon_H8=>(zenon_imply _ _ (fun zenon_H7=>(zenon_H7 zenon_H6)) (fun
zenon_H5=>(zenon_G zenon_H5)) zenon_H8)) zenon_H9))
_p_Nat_equal_symmetric)) zenon_Hc)) zenon_Hd))
_p_Nat_predecessor_reverses_successor)))).
Qed.

          Theorem __B_1_1_LEMMA :
            Is_true ((_p_Nat_equal (_p_Nat_predecessor (_p_Nat_successor n))
                       n)).
          apply for_zenon___B_1_1_LEMMA ;
          auto.
          Qed.
          End __B_1_1.
        Section __B_1_2.
(* File "iterators.fcl", line 73, character 65, line 74, character 58 *)
Theorem for_zenon___B_1_2_LEMMA:(~(Is_true (_p_Nat_equal (
_p_Nat_successor n) _p_Nat_start))).
Proof.
exact(
(NNPP _ (fun zenon_G=>(zenon_G (fun zenon_H2=>(zenon_all _p_Nat_T (fun
n:_p_Nat_T=>(~(Is_true (_p_Nat_equal (_p_Nat_successor n) _p_Nat_start))
)) n (fun zenon_H3=>(zenon_H3 zenon_H2))
_p_Nat_successor_is_non_trivial)))))).
Qed.

          Theorem __B_1_2_LEMMA :
            ~Is_true (((_p_Nat_equal (_p_Nat_successor n) _p_Nat_start))).
          apply for_zenon___B_1_2_LEMMA ;
          auto.
          Qed.
          End __B_1_2.
        Section __B_1_3.
          (* Theorem's body. *)
          Theorem __B_1_3_LEMMA :
            Is_true ((_p_S_equal
                       (_p_F_binary_binop x
                         (abst_iterate x
                           (_p_Nat_predecessor (_p_Nat_successor n))))
                       (_p_F_binary_binop x (abst_iterate x n)))).
          (* Proof assumed because " ". *)
          apply coq_builtins.magic_prove.
          Qed.
          End __B_1_3.
        Section __B_1_4.
(* File "iterators.fcl", line 80, character 95, line 81, character 79 *)
Theorem for_zenon___B_1_4_LEMMA:(Is_true (_p_S_equal (abst_iterate x (
_p_Nat_successor n)) (_p_F_binary_binop x (abst_iterate x (
_p_Nat_predecessor (_p_Nat_successor n)))))).
Proof.
exact(
(NNPP _ (fun zenon_G=>(let zenon_Hb:=zenon_G in (zenon_focal_ite_rel_nl
(fun zenon_Vf zenon_Vg=>(Is_true (_p_S_equal zenon_Vf zenon_Vg))) (
_p_Nat_equal (_p_Nat_successor n) _p_Nat_start) _p_zero_zero (
_p_F_binary_binop x (iterate x (_p_Nat_predecessor (_p_Nat_successor n))
)) (_p_F_binary_binop x (abst_iterate x (_p_Nat_predecessor (
_p_Nat_successor n)))) (fun zenon_H3 zenon_Ha=>(__B_1_2_LEMMA zenon_H3))
 (fun __B_1_2_LEMMA zenon_H4=>(zenon_all _p_S_T (fun x:_p_S_T=>(Is_true
(_p_S_equal x x))) (_p_F_binary_binop x (iterate x (_p_Nat_predecessor (
_p_Nat_successor n)))) (fun zenon_H5=>(zenon_subst _ (fun zenon_Vh=>(
Is_true zenon_Vh)) (_p_S_equal (_p_F_binary_binop x (iterate x (
_p_Nat_predecessor (_p_Nat_successor n)))) (_p_F_binary_binop x (
iterate x (_p_Nat_predecessor (_p_Nat_successor n))))) (_p_S_equal (
_p_F_binary_binop x (iterate x (_p_Nat_predecessor (_p_Nat_successor n))
)) (_p_F_binary_binop x (abst_iterate x (_p_Nat_predecessor (
_p_Nat_successor n))))) (fun zenon_H6=>(zenon_subst _ (fun zenon_Vi=>(~(
(_p_S_equal (_p_F_binary_binop x (iterate x (_p_Nat_predecessor (
_p_Nat_successor n)))) zenon_Vi) = (_p_S_equal (_p_F_binary_binop x (
iterate x (_p_Nat_predecessor (_p_Nat_successor n)))) (
_p_F_binary_binop x (abst_iterate x (_p_Nat_predecessor (
_p_Nat_successor n)))))))) (_p_F_binary_binop x (iterate x (
_p_Nat_predecessor (_p_Nat_successor n)))) (_p_F_binary_binop x (
abst_iterate x (_p_Nat_predecessor (_p_Nat_successor n)))) (fun
zenon_H7=>(zenon_subst _ (fun zenon_Vj=>(~((_p_F_binary_binop x
zenon_Vj) = (_p_F_binary_binop x (abst_iterate x (_p_Nat_predecessor (
_p_Nat_successor n))))))) (iterate x (_p_Nat_predecessor (
_p_Nat_successor n))) (abst_iterate x (_p_Nat_predecessor (
_p_Nat_successor n))) (fun zenon_H9=>(let zenon_H8:=zenon_H9 in (
zenon_noteq _ (abst_iterate x (_p_Nat_predecessor (_p_Nat_successor n)))
 zenon_H8))) (zenon_notnot _ (refl_equal (_p_F_binary_binop x (
abst_iterate x (_p_Nat_predecessor (_p_Nat_successor n)))))) zenon_H7))
(zenon_notnot _ (refl_equal (_p_S_equal (_p_F_binary_binop x (iterate x
(_p_Nat_predecessor (_p_Nat_successor n)))) (_p_F_binary_binop x (
abst_iterate x (_p_Nat_predecessor (_p_Nat_successor n))))))) zenon_H6))
 zenon_H4 zenon_H5)) _p_S_equal_reflexive)) zenon_Hb))))).
Qed.

          Theorem __B_1_4_LEMMA :
            Is_true ((_p_S_equal (abst_iterate x (_p_Nat_successor n))
                       (_p_F_binary_binop x
                         (abst_iterate x
                           (_p_Nat_predecessor (_p_Nat_successor n)))))).
          apply for_zenon___B_1_4_LEMMA ;
          auto.
          Qed.
          End __B_1_4.
(* File "iterators.fcl", line 82, character 20, line 83, character 51 *)
Theorem for_zenon___B_1_LEMMA:(Is_true (_p_S_equal (abst_iterate x (
_p_Nat_successor n)) (_p_F_binary_binop x (abst_iterate x n)))).
Proof.
exact(
(NNPP _ (fun zenon_G=>(zenon_all _p_S_T (fun x:_p_S_T=>(forall y:_p_S_T,
(forall z:_p_S_T,((Is_true (_p_S_equal x y))->((Is_true (_p_S_equal y z)
)->(Is_true (_p_S_equal x z))))))) (abst_iterate x (_p_Nat_successor n))
 (fun zenon_Ha=>(zenon_all _p_S_T (fun y:_p_S_T=>(forall z:_p_S_T,((
Is_true (_p_S_equal (abst_iterate x (_p_Nat_successor n)) y))->((
Is_true (_p_S_equal y z))->(Is_true (_p_S_equal (abst_iterate x (
_p_Nat_successor n)) z)))))) (_p_F_binary_binop x (abst_iterate x (
_p_Nat_predecessor (_p_Nat_successor n)))) (fun zenon_H9=>(zenon_all
_p_S_T (fun z:_p_S_T=>((Is_true (_p_S_equal (abst_iterate x (
_p_Nat_successor n)) (_p_F_binary_binop x (abst_iterate x (
_p_Nat_predecessor (_p_Nat_successor n))))))->((Is_true (_p_S_equal (
_p_F_binary_binop x (abst_iterate x (_p_Nat_predecessor (
_p_Nat_successor n)))) z))->(Is_true (_p_S_equal (abst_iterate x (
_p_Nat_successor n)) z))))) (_p_F_binary_binop x (abst_iterate x n)) (
fun zenon_H8=>(zenon_imply _ _ (fun zenon_H7=>(zenon_H7 __B_1_4_LEMMA))
(fun zenon_H6=>(zenon_imply _ _ (fun zenon_H5=>(zenon_H5 __B_1_3_LEMMA))
 (fun zenon_H4=>(zenon_G zenon_H4)) zenon_H6)) zenon_H8)) zenon_H9))
zenon_Ha)) _p_S_equal_transitive)))).
Qed.

        Theorem __B_1_LEMMA :
          Is_true ((_p_S_equal (abst_iterate x (_p_Nat_successor n))
                     (_p_F_binary_binop x (abst_iterate x n)))).
        apply for_zenon___B_1_LEMMA ;
        auto.
        Qed.
        End __B_1.
(* File "iterators.fcl", line 83, character 51, line 84, character 20 *)
Theorem for_zenon_iterate_spec_ind:(forall x:_p_S_T,(forall n:_p_Nat_T,(
Is_true (_p_S_equal (abst_iterate x (_p_Nat_successor n)) (
_p_F_binary_binop x (abst_iterate x n)))))).
Proof.
exact(
(NNPP _ (fun zenon_G=>(zenon_G __B_1_LEMMA)))).
Qed.

      (* Dummy theorem to enforce Coq abstractions. *)
      Theorem for_zenon_abstracted_iterate_spec_ind :
        forall x : _p_S_T,
          forall n : _p_Nat_T,
            Is_true ((_p_S_equal (abst_iterate x (_p_Nat_successor n))
                       (_p_F_binary_binop x (abst_iterate x n)))).
      assert (__force_use_p_Nat_T := _p_Nat_T).
      assert (__force_use_p_S_T := _p_S_T).
      assert (__force_use__p_Nat_lt := _p_Nat_lt).
      assert (__force_use__p_Nat_predecessor := _p_Nat_predecessor).
      assert (__force_use__p_Nat_start := _p_Nat_start).
      assert (__force_use__p_Nat_successor := _p_Nat_successor).
      assert (__force_use__p_Nat_equal := _p_Nat_equal).
      assert (__force_use__p_Nat_predecessor_reverses_successor :=
        _p_Nat_predecessor_reverses_successor).
      assert (__force_use__p_Nat_successor_is_non_trivial :=
        _p_Nat_successor_is_non_trivial).
      assert (__force_use__p_Nat_equal_reflexive := _p_Nat_equal_reflexive).
      assert (__force_use__p_Nat_equal_symmetric := _p_Nat_equal_symmetric).
      assert (__force_use__p_Nat_equal_transitive :=
        _p_Nat_equal_transitive).
      assert (__force_use__p_S_equal := _p_S_equal).
      assert (__force_use__p_S_equal_reflexive := _p_S_equal_reflexive).
      assert (__force_use__p_S_equal_transitive := _p_S_equal_transitive).
      assert (__force_use__p_F_binary_binop := _p_F_binary_binop).
      assert (__force_use__p_zero_zero := _p_zero_zero).
      assert (__force_use_abst_iterate := abst_iterate).
      apply for_zenon_iterate_spec_ind ;
      auto.
      Qed.
      End Proof_of_iterate_spec_ind.
    
    Theorem iterate_spec_ind  (_p_Nat_T : Set) (_p_S_T : Set) (_p_Nat_lt :
      _p_Nat_T -> _p_Nat_T -> basics.bool__t) (_p_Nat_predecessor :
      _p_Nat_T -> _p_Nat_T) (_p_Nat_start : _p_Nat_T) (_p_Nat_successor :
      _p_Nat_T -> _p_Nat_T) (_p_Nat_equal :
      _p_Nat_T -> _p_Nat_T -> basics.bool__t)
      (_p_Nat_predecessor_reverses_successor :
      forall x  y : _p_Nat_T,
        Is_true ((_p_Nat_equal x (_p_Nat_successor y))) ->
          Is_true ((_p_Nat_equal y (_p_Nat_predecessor x))))
      (_p_Nat_successor_is_non_trivial :
      forall n : _p_Nat_T,
        ~Is_true (((_p_Nat_equal (_p_Nat_successor n) _p_Nat_start))))
      (_p_Nat_equal_reflexive :
      forall x : _p_Nat_T, Is_true ((_p_Nat_equal x x)))
      (_p_Nat_equal_symmetric :
      forall x  y : _p_Nat_T,
        Is_true ((_p_Nat_equal x y)) -> Is_true ((_p_Nat_equal y x)))
      (_p_Nat_equal_transitive :
      forall x  y  z : _p_Nat_T,
        Is_true ((_p_Nat_equal x y)) ->
          Is_true ((_p_Nat_equal y z)) -> Is_true ((_p_Nat_equal x z)))
      (_p_S_equal : _p_S_T -> _p_S_T -> basics.bool__t)
      (_p_S_equal_reflexive : forall x : _p_S_T, Is_true ((_p_S_equal x x)))
      (_p_S_equal_transitive :
      forall x  y  z : _p_S_T,
        Is_true ((_p_S_equal x y)) ->
          Is_true ((_p_S_equal y z)) -> Is_true ((_p_S_equal x z)))
      (_p_F_binary_binop : _p_S_T -> _p_S_T -> _p_S_T) (_p_zero_zero :
      _p_S_T) (abst_iterate := iterate _p_Nat_T _p_S_T _p_Nat_lt
      _p_Nat_predecessor _p_Nat_start _p_Nat_equal _p_F_binary_binop
      _p_zero_zero):
      forall x : _p_S_T,
        forall n : _p_Nat_T,
          Is_true ((_p_S_equal (abst_iterate x (_p_Nat_successor n))
                     (_p_F_binary_binop x (abst_iterate x n)))).
    apply for_zenon_abstracted_iterate_spec_ind ;
    auto.
    Qed.
    
    (* Fully defined 'Iteration' species's collection generator. *)
    Definition collection_create (_p_Nat_T : Set) (_p_S_T : Set)
      (_p_F_binary_T : Set) _p_zero_zero _p_Nat_lt _p_Nat_predecessor
      _p_Nat_start _p_Nat_successor _p_Nat_equal
      _p_Nat_predecessor_reverses_successor _p_Nat_successor_is_non_trivial
      _p_Nat_equal_reflexive _p_Nat_equal_symmetric _p_Nat_equal_transitive
      _p_S_equal _p_S_equal_reflexive _p_S_equal_transitive
      _p_F_binary_binop :=
      let local_rep := basics.unit__t in
      (* From species iterators#Iteration. *)
      let local_iterate := iterate _p_Nat_T _p_S_T _p_Nat_lt
        _p_Nat_predecessor _p_Nat_start _p_Nat_equal _p_F_binary_binop
        _p_zero_zero in
      (* From species iterators#Iteration. *)
      let local_iterate_spec_base := iterate_spec_base _p_Nat_T _p_S_T
        _p_Nat_lt _p_Nat_predecessor _p_Nat_start _p_Nat_equal
        _p_Nat_equal_reflexive _p_S_equal _p_S_equal_reflexive
        _p_F_binary_binop _p_zero_zero in
      (* From species iterators#Iteration. *)
      let local_iterate_spec_ind := iterate_spec_ind _p_Nat_T _p_S_T
        _p_Nat_lt _p_Nat_predecessor _p_Nat_start _p_Nat_successor
        _p_Nat_equal _p_Nat_predecessor_reverses_successor
        _p_Nat_successor_is_non_trivial _p_Nat_equal_reflexive
        _p_Nat_equal_symmetric _p_Nat_equal_transitive _p_S_equal
        _p_S_equal_reflexive _p_S_equal_transitive _p_F_binary_binop
        _p_zero_zero in
      mk_record (_p_Nat_T : Set) (_p_S_T : Set) (_p_F_binary_T : Set)
      _p_zero_zero _p_Nat_start _p_Nat_successor _p_S_equal _p_F_binary_binop
      local_rep local_iterate local_iterate_spec_base local_iterate_spec_ind.
    
End Iteration.
  
  Module Dichotomic_system.
    Record Dichotomic_system : Type :=
      mk_record {
      rf_T :> Set ;
      (* From species iterators#Dichotomic_system. *)
      rf_div2 : rf_T -> rf_T ;
      (* From species sets#Setoid. *)
      rf_equal : rf_T -> rf_T -> basics.bool__t ;
      (* From species iterators#Dichotomic_system. *)
      rf_is_even : rf_T -> basics.bool__t ;
      (* From species iterators#Dichotomic_system. *)
      rf_is_odd : rf_T -> basics.bool__t ;
      (* From species iterators#Dichotomic_system. *)
      rf_mult2 : rf_T -> rf_T ;
      (* From species constants#Setoid_with_one. *)
      rf_one : rf_T ;
      (* From species integers#Enumeration_system. *)
      rf_predecessor : rf_T -> rf_T ;
      (* From species integers#Enumeration_system. *)
      rf_successor : rf_T -> rf_T ;
      (* From species constants#Setoid_with_zero. *)
      rf_zero : rf_T ;
      (* From species sets#Setoid. *)
      rf_different : rf_T -> rf_T -> basics.bool__t ;
      (* From species iterators#Dichotomic_system. *)
      rf_div2_inverses_even :
        forall n : rf_T,
          Is_true ((rf_is_even n)) ->
            Is_true ((rf_equal (rf_mult2 (rf_div2 n)) n)) ;
      (* From species constants#Setoid_with_one. *)
      rf_element : rf_T ;
      (* From species sets#Setoid. *)
      rf_equal_reflexive : forall x : rf_T, Is_true ((rf_equal x x)) ;
      (* From species sets#Setoid. *)
      rf_equal_symmetric :
        forall x  y : rf_T,
          Is_true ((rf_equal x y)) -> Is_true ((rf_equal y x)) ;
      (* From species sets#Setoid. *)
      rf_equal_transitive :
        forall x  y  z : rf_T,
          Is_true ((rf_equal x y)) ->
            Is_true ((rf_equal y z)) -> Is_true ((rf_equal x z)) ;
      (* From species iterators#Dichotomic_system. *)
      rf_even_odd_complete :
        forall n : rf_T, Is_true ((rf_is_odd n)) \/ Is_true ((rf_is_even n)) ;
      (* From species iterators#Dichotomic_system. *)
      rf_is_even_substitution_rule :
        forall n  m : rf_T,
          Is_true ((rf_is_even n)) ->
            Is_true ((rf_equal n m)) -> Is_true ((rf_is_even m)) ;
      (* From species iterators#Dichotomic_system. *)
      rf_is_odd_substitution_rule :
        forall n  m : rf_T,
          Is_true ((rf_is_odd n)) ->
            Is_true ((rf_equal n m)) -> Is_true ((rf_is_odd m)) ;
      (* From species constants#Setoid_with_one. *)
      rf_is_one : rf_T -> basics.bool__t ;
      (* From species iterators#Dichotomic_system. *)
      rf_mult2_is_injective :
        forall n  m : rf_T,
          Is_true ((rf_equal (rf_mult2 n) (rf_mult2 m))) ->
            Is_true ((rf_equal n m)) ;
      (* From species iterators#Dichotomic_system. *)
      rf_mult2_produces_even :
        forall n : rf_T, Is_true ((rf_is_even (rf_mult2 n))) ;
      (* From species iterators#Dichotomic_system. *)
      rf_mult2_substitution_rule :
        forall n  m : rf_T,
          Is_true ((rf_equal n m)) ->
            Is_true ((rf_equal (rf_mult2 n) (rf_mult2 m))) ;
      (* From species iterators#Dichotomic_system. *)
      rf_one_is_odd : Is_true ((rf_is_odd rf_one)) ;
      (* From species basics#Basic_object. *)
      rf_parse : basics.string__t -> rf_T ;
      (* From species basics#Basic_object. *)
      rf_print : rf_T -> basics.string__t ;
      (* From species iterators#Dichotomic_system. *)
      rf_div2_inverses_odd :
        forall n : rf_T,
          Is_true ((rf_is_odd n)) ->
            Is_true ((rf_equal (rf_successor (rf_mult2 (rf_div2 n))) n)) ;
      (* From species integers#Enumeration_system. *)
      rf_predecessor_reverses_successor :
        forall x  y : rf_T,
          Is_true ((rf_equal x (rf_successor y))) ->
            Is_true ((rf_equal y (rf_predecessor x))) ;
      (* From species integers#Enumeration_system. *)
      rf_successor_is_injective :
        forall x  y : rf_T,
          Is_true ((rf_equal (rf_successor x) (rf_successor y))) ->
            Is_true ((rf_equal x y)) ;
      (* From species iterators#Dichotomic_system. *)
      rf_successor_of_even_is_odd :
        forall n : rf_T,
          Is_true ((rf_is_even n)) -> Is_true ((rf_is_odd (rf_successor n))) ;
      (* From species iterators#Dichotomic_system. *)
      rf_successor_of_odd_is_even :
        forall n : rf_T,
          Is_true ((rf_is_odd n)) -> Is_true ((rf_is_even (rf_successor n))) ;
      (* From species integers#Enumeration_system. *)
      rf_successor_substitution_rule :
        forall x  y : rf_T,
          Is_true ((rf_equal x y)) ->
            Is_true ((rf_equal (rf_successor x) (rf_successor y))) ;
      (* From species constants#Setoid_with_zero. *)
      rf_is_zero : rf_T -> basics.bool__t ;
      (* From species iterators#Dichotomic_system. *)
      rf_one_successes_zero :
        Is_true ((rf_equal (rf_successor rf_zero) rf_one)) ;
      (* From species iterators#Dichotomic_system. *)
      rf_start : rf_T ;
      (* From species iterators#Dichotomic_system. *)
      rf_zero_fixes_mult2 : Is_true ((rf_equal (rf_mult2 rf_zero) rf_zero)) ;
      (* From species iterators#Dichotomic_system. *)
      rf_zero_images_by_div2 :
        forall n : rf_T,
          Is_true ((rf_equal (rf_div2 n) rf_zero)) ->
            (Is_true ((rf_equal n rf_zero)) \/ Is_true ((rf_equal n rf_one))) ;
      (* From species iterators#Dichotomic_system. *)
      rf_zero_is_even : Is_true ((rf_is_even rf_zero)) ;
      (* From species sets#Setoid. *)
      rf_same_is_not_different :
        forall x  y : rf_T,
          Is_true ((rf_different x y)) <-> ~Is_true (((rf_equal x y))) ;
      (* From species constants#Setoid_with_one. *)
      rf_is_one_spec :
        forall x : rf_T,
          Is_true ((rf_is_one x)) <->
            (Is_true ((rf_equal x rf_one)) \/ Is_true ((rf_equal rf_one x))) ;
      (* From species constants#Setoid_with_zero. *)
      rf_is_zero_spec :
        forall x : rf_T,
          Is_true ((rf_is_zero x)) <->
            (Is_true ((rf_equal x rf_zero)) \/ Is_true ((rf_equal rf_zero x))) ;
      (* From species sets#Setoid. *)
      rf_different_is_complete :
        forall x  y  z : rf_T,
          Is_true ((rf_different x y)) ->
            (Is_true ((rf_different x z)) \/ Is_true ((rf_different y z))) ;
      (* From species sets#Setoid. *)
      rf_different_is_irreflexive :
        forall x : rf_T, ~Is_true (((rf_different x x))) ;
      (* From species sets#Setoid. *)
      rf_different_is_symmetric :
        forall x  y : rf_T,
          Is_true ((rf_different x y)) -> Is_true ((rf_different y x)) ;
      (* From species constants#Setoid_with_zero. *)
      rf_zero_checks_to_zero : Is_true ((rf_is_zero rf_zero))
      }.
    
    Definition start (abst_T : Set) (abst_zero : abst_T) : abst_T :=
      abst_zero.
    
    (* From species iterators#Dichotomic_system. *)
    Theorem zero_images_by_div2  (abst_T : Set)
      (abst_div2 : abst_T -> abst_T)
      (abst_equal : abst_T -> abst_T -> basics.bool__t) (abst_one : abst_T)
      (abst_zero : abst_T):
      forall n : abst_T,
        Is_true ((abst_equal (abst_div2 n) abst_zero)) ->
          (Is_true ((abst_equal n abst_zero)) \/
             Is_true ((abst_equal n abst_one))).
    (* Proof assumed because " Because todo ". *)
    apply coq_builtins.magic_prove.
    Qed.
    
End Dichotomic_system.
  
  Module Dichotomy.
    Record Dichotomy (Nat_T : Set) (S_T : Set) (Bins_T : Set) (_p_stop_stop :
                                                               S_T) : Type :=
      mk_record {
      rf_T :> Set ;
      (* From species iterators#Dichotomy. *)
      rf_dichot : S_T -> Nat_T -> S_T ;
      (* From species basics#Basic_object. *)
      rf_parse : basics.string__t -> rf_T ;
      (* From species basics#Basic_object. *)
      rf_print : rf_T -> basics.string__t
      }.
    
    Module Termination_dichot_namespace.
      Section dichot.
        Variable _p_Nat_T : Set.
        Variable _p_S_T : Set.
        Variable _p_Nat_div2 : _p_Nat_T -> _p_Nat_T.
        Variable _p_Nat_equal : _p_Nat_T -> _p_Nat_T -> basics.bool__t.
        Variable _p_Nat_is_odd : _p_Nat_T -> basics.bool__t.
        Variable _p_Nat_zero : _p_Nat_T.
        Variable _p_Bins_binop : _p_S_T -> _p_S_T -> _p_S_T.
        Variable _p_stop_stop : _p_S_T.
        
        
        (* Abstracted termination order. *)
        Variable __term_order :
          (((_p_S_T) * (_p_Nat_T))%type) -> (((_p_S_T) * (_p_Nat_T))%type) -> Prop.
        Variable __term_obl :(forall x : _p_S_T, forall n : _p_Nat_T,
          forall n_2 : _p_Nat_T, (n_2 = (_p_Nat_div2 n)) -> ~
          Is_true ((_p_Nat_equal n_2 _p_Nat_zero)) -> __term_order (x, n_2)
          (x, n))
          /\
           (well_founded __term_order).
        
        Function dichot (__arg: (((_p_S_T) * (_p_Nat_T))%type))
          {wf __term_order __arg}: _p_S_T
          :=
          match __arg with
            | (x, n) =>
            let n_2 : _p_Nat_T := (_p_Nat_div2 n)
            in
            if (_p_Nat_equal n_2 _p_Nat_zero)
              then if (_p_Nat_equal n _p_Nat_zero) then _p_stop_stop
                     else (_p_Bins_binop x _p_stop_stop)
              else let e : _p_S_T := (dichot (x, n_2))
              in
              if (_p_Nat_is_odd n) then (_p_Bins_binop x (_p_Bins_binop e e))
                else (_p_Bins_binop e e)
            end.
          Proof.
            assert (__force_use_p_Nat_T := _p_Nat_T).
            assert (__force_use_p_S_T := _p_S_T).
            assert (__force_use__p_Nat_div2 := _p_Nat_div2).
            assert (__force_use__p_Nat_equal := _p_Nat_equal).
            assert (__force_use__p_Nat_is_odd := _p_Nat_is_odd).
            assert (__force_use__p_Nat_zero := _p_Nat_zero).
            assert (__force_use__p_Bins_binop := _p_Bins_binop).
            assert (__force_use__p_stop_stop := _p_stop_stop).
            apply coq_builtins.magic_prove.
            apply coq_builtins.magic_prove.
            Qed.
          Definition Dichotomy__dichot x  n := dichot (x, n).
          End dichot.
        End Termination_dichot_namespace.
      Definition dichot (_p_Nat_T : Set) (_p_S_T : Set) (_p_Nat_div2 :
        _p_Nat_T -> _p_Nat_T) (_p_Nat_equal :
        _p_Nat_T -> _p_Nat_T -> basics.bool__t) (_p_Nat_is_odd :
        _p_Nat_T -> basics.bool__t) (_p_Nat_zero : _p_Nat_T) (_p_Bins_binop :
        _p_S_T -> _p_S_T -> _p_S_T) (_p_stop_stop : _p_S_T) :=
        Termination_dichot_namespace.Dichotomy__dichot _p_Nat_T _p_S_T
        _p_Nat_div2 _p_Nat_equal _p_Nat_is_odd _p_Nat_zero _p_Bins_binop
        _p_stop_stop coq_builtins.magic_order.
      
      (* Fully defined 'Dichotomy' species's collection generator. *)
      Definition collection_create (_p_Nat_T : Set) (_p_S_T : Set)
        (_p_Bins_T : Set) _p_stop_stop _p_Nat_div2 _p_Nat_equal _p_Nat_is_odd
        _p_Nat_zero _p_Bins_binop :=
        let local_rep := basics.unit__t in
        (* From species iterators#Dichotomy. *)
        let local_dichot := dichot _p_Nat_T _p_S_T _p_Nat_div2 _p_Nat_equal
          _p_Nat_is_odd _p_Nat_zero _p_Bins_binop _p_stop_stop in
        (* From species basics#Basic_object. *)
        let local_parse := basics.Basic_object.parse local_rep in
        (* From species basics#Basic_object. *)
        let local_print := basics.Basic_object.print local_rep in
        mk_record (_p_Nat_T : Set) (_p_S_T : Set) (_p_Bins_T : Set)
        _p_stop_stop local_rep local_dichot local_parse local_print.
      
End Dichotomy.
    
    