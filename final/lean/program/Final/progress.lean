import Final.arith
import Final.inversion

theorem progress : ∀ e : Expr, val e ∨ (∃ e', e ↦ e') := by
  intro e
  cases e
  case Num n =>
    apply Or.inl
    apply val.DNat n
  case Binop binop el er =>
    apply Or.inr
    have hl: val el ∨ (∃ el', el ↦ el') := progress el
    have hr: val er ∨ (∃ er', er ↦ er') := progress er
    apply Or.elim hl
    . apply Or.elim hr
      . intro hrval
        intro hlval
        have hlnum: ∃ n : Nat, el = Expr.Num n := val_inversion el hlval
        have hrnum: ∃ n : Nat, er = Expr.Num n := val_inversion er hrval
        apply Exists.elim hlnum
        intro nl hl
        apply Exists.elim hrnum
        intro nr hr
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
