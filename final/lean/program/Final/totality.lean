import Final.arith
import Final.inversion
import Final.evals

theorem totality : ∀ e : Expr, ∃ e' : Expr, val e' ∧ e ↦* e' := by
  intro e
  induction e
  case Num n =>
    exists Expr.Num n
    apply And.intro (val.DNat n) (evals_refl (Expr.Num n))
  case Binop op el er ihl ihr =>
    -- left IH
    apply Exists.elim ihl
    intro el_val hl
    have hll: ∃ n : Nat, el_val = Expr.Num n := val_inversion el_val hl.left
    apply Exists.elim hll
    intro nl hnl
    -- right IH
    apply Exists.elim ihr
    intro er_val hr
    have hrl: ∃ n : Nat, er_val = Expr.Num n := val_inversion er_val hr.left
    apply Exists.elim hrl
    intro nr hnr
    -- the `e'`
    exists Expr.Num (apply_binop op nl nr)
    -- prove `val e' ∧ e ↦* e'`
    constructor
    -- left
    apply val.DNat (apply_binop op nl nr)
    -- right
    have hstep: Expr.Binop op el_val er_val ↦ Expr.Num (apply_binop op nl nr) := by
      simp [hnl, hnr]
      apply steps.DOp op nl nr
    calc
      Expr.Binop op el er ↦* Expr.Binop op el_val er :=
        transitive_left op el el_val er hl.right
      _ ↦* Expr.Binop op el_val er_val :=
        transitive_right op el_val er er_val hl.left hr.right
      _ ↦* Expr.Num (apply_binop op nl nr) :=
        evals.Step (Expr.Binop op el_val er_val)
                   (Expr.Num (apply_binop op nl nr))
                   (Expr.Num (apply_binop op nl nr))
                   hstep (evals.Val (Expr.Num (apply_binop op nl nr)))
