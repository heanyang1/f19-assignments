import Final.arith

@[simp]
theorem val_inversion : ∀ e : Expr, val e → ∃ n : Nat, e = Expr.Num n :=
  sorry -- Remove this line and add your proof
