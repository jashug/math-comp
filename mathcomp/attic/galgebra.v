(* (c) Copyright 2006-2016 Microsoft Corporation and Inria.                  *)
(* Distributed under the terms of CeCILL-B.                                  *)
Require Import mathcomp.ssreflect.ssreflect.
From mathcomp
Require Import ssrbool ssrfun eqtype ssrnat seq choice fintype finfun.
From mathcomp
Require Import bigop finset ssralg fingroup zmodp matrix vector falgebra.

(*****************************************************************************)
(*  * Finite Group as an algebra                                             *)
(*    (galg F gT)       ==  the algebra generated by gT on F                 *)
(*****************************************************************************)

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Reserved Notation "g %:FG"
  (at level 2, left associativity, format "g %:FG").

Local Open Scope ring_scope.
Import GRing.Theory.

Section GroupAlgebraDef.
Variables (F : fieldType) (gT : finGroupType).

Inductive galg : predArgType := GAlg of {ffun gT -> F}.

Definition galg_val A := let: GAlg f := A in f.

Canonical galg_subType := Eval hnf in [newType for galg_val].
Definition galg_eqMixin := Eval hnf in [eqMixin of galg by <:].
Canonical galg_eqType := Eval hnf in EqType galg galg_eqMixin.
Definition galg_choiceMixin := [choiceMixin of galg by <:].
Canonical galg_choiceType := Eval hnf in ChoiceType galg galg_choiceMixin.

Definition fun_of_galg A (i : gT) := galg_val A i.

Coercion fun_of_galg : galg >-> Funclass.

Lemma galgE : forall f, GAlg (finfun f) =1 f.
Proof. by move=> f i; rewrite /fun_of_galg ffunE. Qed.

Definition injG (g : gT) :=  GAlg ([ffun k => (k == g)%:R]).
Local Notation "g %:FG" := (injG g).

Implicit Types v: galg.

Definition g0 := GAlg 0.
Definition g1 := 1%g %:FG.
Definition opprg v :=  GAlg (-galg_val v).
Definition addrg v1 v2 := GAlg (galg_val v1 + galg_val v2).
Definition mulvg a v :=  GAlg ([ffun k => a * galg_val v k]).
Definition mulrg v1 v2 :=
 GAlg ([ffun g => \sum_(k : gT) (v1 k) * (v2 ((k^-1) * g)%g)]).

Lemma addrgA : associative addrg.
Proof. 
by move=> *; apply: val_inj; apply/ffunP=> ?; rewrite !ffunE addrA.
Qed.
Lemma addrgC : commutative addrg.
Proof. 
by move=> *; apply: val_inj; apply/ffunP=> ?; rewrite !ffunE addrC.
Qed.
Lemma addr0g : left_id g0 addrg.
Proof.
by move=> *; apply: val_inj; apply/ffunP=> ?; rewrite !ffunE add0r.
Qed.
Lemma addrNg : left_inverse g0 opprg addrg.
Proof.
by move=> *; apply: val_inj; apply/ffunP=> ?; rewrite !ffunE addNr.
Qed.

(* abelian group structure *)
Definition gAlgZmodMixin := ZmodMixin addrgA addrgC addr0g addrNg.
Canonical Structure gAlgZmodType :=
 Eval hnf in ZmodType galg gAlgZmodMixin.

Lemma GAlg_morph : {morph GAlg: x y / x + y}.
Proof. by move=> f1 f2; apply/eqP. Qed.

Lemma mulvgA : forall a b v, mulvg a (mulvg b v) = mulvg (a * b) v.
Proof.
by move=> *; apply: val_inj; apply/ffunP=> g; rewrite !ffunE mulrA.
Qed.

Lemma mulvg1 : forall v, mulvg 1 v = v.
Proof. by move=> v; apply: val_inj; apply/ffunP=> g; rewrite ffunE mul1r. Qed.

Lemma mulvg_addr : forall a u v, mulvg a (u + v) = (mulvg a u) + (mulvg a v).
Proof.
by move=> *; apply: val_inj; apply/ffunP=> g; rewrite !ffunE mulrDr.
Qed.

Lemma mulvg_addl : forall u a b, mulvg (a + b) u = (mulvg a u) + (mulvg b u).
Proof.
by move=> *; apply: val_inj; apply/ffunP=> g; rewrite !ffunE mulrDl.
Qed.

Definition gAlgLmodMixin := LmodMixin mulvgA mulvg1 mulvg_addr mulvg_addl.
Canonical gAlgLmodType := Eval hnf in LmodType F galg gAlgLmodMixin.

Lemma sum_fgE : forall I r (P : pred I) (E : I -> galg) i,
  (\sum_(k <- r | P k) E k) i = \sum_(k <- r | P k) E k i.
Proof.
move=> I r P E i.
by apply: (big_morph (fun A : galg => A i)) => [A B|]; rewrite galgE.
Qed.

Lemma mulrgA : associative mulrg.
Proof.
move=> x y z; apply: val_inj; apply/ffunP=> g; rewrite !ffunE; symmetry.
rewrite (eq_bigr (fun k => \sum_i x i * (y (i^-1 * k)%g * z (k^-1 * g)%g)))
 => [| *]; last by rewrite galgE big_distrl; apply: eq_bigr => *; rewrite mulrA.
rewrite exchange_big /=.
transitivity (\sum_j x j * \sum_i y (j^-1 * i)%g * z (i^-1 * g)%g).
  by apply: eq_bigr => i _; rewrite big_distrr /=.
apply: eq_bigr => i _; rewrite galgE (reindex (fun j => (i * j)%g)); last first.
  by exists [eta mulg i^-1] => /= j _; rewrite mulgA 1?mulgV 1?mulVg mul1g.
by congr (_ * _); apply: eq_bigr => *; rewrite mulgA mulVg mul1g invMg mulgA.
Qed.

Lemma mulr1g : left_id g1 mulrg.
Proof.
move=> x; apply: val_inj; apply/ffunP=> g.
rewrite ffunE (bigD1 1%g) //= galgE eqxx invg1.
by rewrite mul1g mul1r big1 1?addr0 // => i Hi; rewrite galgE (negbTE Hi) mul0r.
Qed.

Lemma mulrg1 : right_id g1 mulrg.
Proof.
move=> x; apply: val_inj; apply/ffunP=> g.
rewrite ffunE (bigD1 g) //= galgE mulVg eqxx mulr1.
by rewrite big1 1?addr0 // => i Hi; rewrite galgE -eq_mulVg1 (negbTE Hi) mulr0.
Qed.

Lemma mulrg_addl : left_distributive mulrg addrg.
Proof.
move=> x y z; apply: val_inj; apply/ffunP=> g; rewrite !ffunE -big_split /=.
by apply: eq_bigr => i _; rewrite galgE mulrDl.
Qed.

Lemma mulrg_addr : right_distributive mulrg addrg.
Proof.
move=> x y z; apply: val_inj; apply/ffunP=> g; rewrite !ffunE -big_split /=.
by apply: eq_bigr => i _; rewrite galgE mulrDr.
Qed.

Lemma nong0g1 : g1 != 0 :> galg.
Proof.
apply/eqP; case.
move/ffunP; move/(_ 1%g); rewrite !ffunE eqxx.
by move/eqP; rewrite oner_eq0.
Qed.

Definition gAlgRingMixin :=
  RingMixin mulrgA mulr1g mulrg1 mulrg_addl mulrg_addr nong0g1.
Canonical gAlgRingType := Eval hnf in RingType galg gAlgRingMixin.

Implicit Types x y : galg.

Lemma mulg_mulvl : forall a x y, a *: (x * y) = (a *: x) * y.
Proof.
move=> a x y; apply: val_inj; apply/ffunP=> g.
rewrite !ffunE big_distrr /=.
by apply: eq_bigr => i _; rewrite mulrA galgE.
Qed.

Lemma mulg_mulvr : forall a x y, a *: (x * y) = x * (a *: y).
Proof.
move=> a x y; apply: val_inj; apply/ffunP=> g.
rewrite !ffunE big_distrr /=.
by apply: eq_bigr => i _; rewrite galgE mulrCA.
Qed.

Canonical gAlgLalgType := Eval hnf in LalgType F galg mulg_mulvl.
Canonical gAlgAlgType := Eval hnf in AlgType F galg mulg_mulvr.

Lemma injGM : forall g h, (g * h)%g %:FG = (g %:FG) * (h %:FG).
Proof.
move=> g h; apply: val_inj; apply/ffunP=> k.
rewrite !ffunE (bigD1 g) //= !galgE eqxx mul1r.
rewrite big1 1?addr0 => [| i Hi]; last by rewrite !galgE (negbTE Hi) mul0r.
by rewrite -(inj_eq (mulgI (g^-1)%g)) mulgA mulVg mul1g.
Qed.

Fact gAlg_iso_vect : Vector.axiom #|gT| galg.
Proof.
exists (fun x => \row_(i < #|gT|) x (enum_val i)) => [k x y | ].
  by apply/rowP=> i; rewrite !mxE !galgE !ffunE.
exists (fun x : 'rV[F]_#|gT| => GAlg ([ffun k => (x 0 (enum_rank k))])) => x.
  by apply: val_inj; apply/ffunP=> i; rewrite ffunE mxE enum_rankK.
by apply/rowP=> i; rewrite // !mxE galgE enum_valK.
Qed.

Definition galg_vectMixin := VectMixin gAlg_iso_vect.
Canonical galg_vectType := VectType F galg galg_vectMixin.

Canonical galg_unitRingType := FalgUnitRingType galg.
Canonical galg_unitAlgFType := [unitAlgType F of galg].
Canonical gAlgAlgFType := [FalgType F of galg].


Variable G : {group gT}.

Definition gvspace: {vspace galg} := (\sum_(g in G) <[g%:FG]>)%VS.

Fact gspace_subproof : has_algid gvspace && (gvspace * gvspace <= gvspace)%VS.
Proof.
apply/andP; split.
  apply: has_algid1.
  rewrite /gvspace (bigD1 (1)%g) //=.
  apply: subv_trans (addvSl _ _).
  by apply/vlineP; exists 1; rewrite scale1r.
apply/prodvP=> u v Hu Hv.
case/memv_sumP: Hu => u_ Hu ->; rewrite big_distrl /=.
apply: memv_suml=> i Hi.
case/memv_sumP: Hv => v_ Hv ->; rewrite big_distrr /=.
apply: memv_suml=> j Hj.
rewrite /gvspace (bigD1 (i*j)%g) /=; last by apply: groupM.
apply: subv_trans (addvSl _ _).
case/vlineP: (Hu _ Hi)=> k ->; case/vlineP: (Hv _ Hj)=> l ->.
apply/vlineP; exists (k * l).
by rewrite -scalerAl -scalerAr scalerA injGM.
Qed.

Definition gaspace : {aspace galg} := ASpace gspace_subproof.

End GroupAlgebraDef.

Notation " g %:FG " := (injG _ g).