import Final.arith
import Final.inversion

theorem progress : ∀ e : Expr, val e ∨ (∃ e', e ↦ e') := by
  intro e
  induction e
  case Num n =>
    apply Or.inl
    apply val.DNat n
  case Binop binop el er ihl ihr =>
    apply Or.inr
    apply Or.elim ihl
    . apply Or.elim ihr
      . intro hrval
        intro hlval
        rcases val_inversion el hlval with ⟨nl, hl⟩
        rcases val_inversion er hrval with ⟨nr, hr⟩
        exists Expr.Num (apply_binop binop nl nr)
        simp [hl, hr]
        apply steps.DOp binop nl nr
      . intro ⟨er', h⟩
        intro hval
        exists Expr.Binop binop el er'
        apply (steps.DRight binop el er er') h hval
    . intro ⟨el', h⟩
      exists Expr.Binop binop el' er
      apply (steps.DLeft binop el el' er) h
