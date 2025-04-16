-- Some proofs from previous year's final

section part1
  variable (p q r s : Prop)
    theorem and_commutativity (h: p ∧ q) : q ∧ p :=
        ⟨ h.right, h.left ⟩

    theorem demorgans_law : ¬(p ∨ q) ↔ ¬p ∧ ¬q :=
    ⟨
        fun h: ¬(p ∨ q) =>
            have hnp: ¬p := fun hp: p =>
                show False from h (Or.inl hp);
            have hnq: ¬q := fun hq: q =>
                show False from h (Or.inr hq);
            show ¬p ∧ ¬q from ⟨ hnp, hnq ⟩,
        fun h: ¬p ∧ ¬q =>
            fun nr: p ∨ q =>
                Or.elim nr (fun hp: p => h.left hp) (fun hq: q => h.right hq)
    ⟩

    theorem contraposition : (p → q) → (¬q → ¬p) :=
        fun himp: p → q =>
            fun hnp: ¬q =>
                fun hp: p =>
                    show False from hnp (himp hp)
end part1

section part2
    variable (α : Type) (p q : α → Prop) (r : Prop)

    theorem and_forall_dist : (∀ x, p x ∧ q x) ↔ (∀ x, p x) ∧ (∀ x, q x) :=
    ⟨
        fun h: ∀ x, p x ∧ q x =>
            ⟨fun y => show p y from (h y).left,
            fun y => show q y from (h y).right⟩,
        fun h: (∀ x, p x) ∧ (∀ x, q x) =>
            fun y => show p y ∧ q y from ⟨h.left y, h.right y⟩
    ⟩

    -- I can't prove unbound_prop without `em` from classical logic.
    open Classical

    theorem unbound_prop : (∀ x, p x ∨ r) ↔ (∀ x, p x) ∨ r :=
    ⟨
        fun h: ∀ x, p x ∨ r =>
            (em r).elim
                (fun hr: r =>
                    show (∀ x, p x) ∨ r from Or.inr hr)
                (fun hnr: ¬ r =>
                    show (∀ x, p x) ∨ r from
                        Or.inl fun y => (h y).resolve_right hnr),
        fun h: (∀ x, p x) ∨ r =>
            h.elim
                (fun hl: ∀ x, p x =>
                    fun y => Or.inl (hl y))
                (fun hr: r =>
                    fun _ => Or.inr (hr))
    ⟩

    variable (men : Type) (barber : men) (shaves : men → men → Prop)

    theorem contradicts {p: Prop} : ¬(p ↔ (¬ p)) :=
        fun h: p ↔ (¬ p) =>
            have hnp: ¬ p := fun hp: p => (h.mp hp) hp;
            have hp: p := h.mpr hnp;
        show False from hnp hp

    theorem barber_paradox : ¬ (∀ x : men, shaves barber x ↔ ¬ shaves x x) :=
        fun h: ∀ x : men, shaves barber x ↔ ¬ shaves x x =>
            show False from contradicts (h barber)
end part2

section part4
    open Classical

    variable (α : Type) (p q : α → Prop) (a : α) (r : Prop)

    theorem dne {p : Prop} (h : ¬¬p) : p :=
        Or.elim (em p)
            (fun hp : p => hp)
            (fun hnp : ¬p => absurd hnp h)

    theorem forall_inverse : (∀ x, p x) ↔ ¬(∃ x, ¬p x) :=
    ⟨
        fun h: ∀ x, p x => byContradiction
            (fun h1: ¬¬(∃ x, ¬p x) =>
                Exists.elim (dne h1)
                (fun w =>
                    fun hw: ¬p w =>
                        show False from hw (h w))),
        fun h: ¬(∃ x, ¬p x) =>
            fun x => byContradiction
                (fun h1: ¬p x =>
                    show False from h ⟨ x, h1 ⟩)

    ⟩

end part4
