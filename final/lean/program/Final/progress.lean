import Final.arith
import Final.inversion

theorem progress : ∀ e : Expr, val e ∨ (∃ e', e ↦ e') := by
  intro e
  match e with
  | Expr.Num n =>
    apply Or.inl
    apply val.DNat n
  | Expr.Binop binop el er =>
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
        simp [hl, hr]
        have hstep: Expr.Binop binop (Expr.Num nl) (Expr.Num nr) ↦ Expr.Num (apply_binop binop nl nr) :=
          (steps.DOp binop nl nr)
        exists Expr.Num (apply_binop binop nl nr)
      . intro ⟨er', h⟩
        intro hval
        have hstep: Expr.Binop binop el er ↦ Expr.Binop binop el er'
          := (steps.DRight binop el er er') h hval
        exists Expr.Binop binop el er'
    . intro ⟨el', h⟩
      have hstep: Expr.Binop binop el er ↦ Expr.Binop binop el' er
        := (steps.DLeft binop el el' er) h
      exists Expr.Binop binop el' er
