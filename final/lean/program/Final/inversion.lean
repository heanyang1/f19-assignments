import Final.arith

theorem val_inversion_tactics : ∀ e : Expr, val e → ∃ n : Nat, e = Expr.Num n := by
    intro e
    intro ve
    cases ve with
    | DNat n0 => exists n0

@[simp]
theorem val_inversion : ∀ e : Expr, val e → ∃ n : Nat, e = Expr.Num n :=
    fun _ =>
        fun ve =>
            val.casesOn ve (
                fun n0 => ⟨ n0, (Eq.refl (Expr.Num n0)) ⟩
            )
