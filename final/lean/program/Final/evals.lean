import Final.arith

inductive evals : Expr → Expr → Prop
| Val (e : Expr) : evals e e
| Step (e e_step e_val: Expr) :
  (e ↦ e_step) → evals e_step e_val → evals e e_val

notation:35 e " ↦* " e' => evals e e'

example : (Expr.Binop Binop.Add (Expr.Num 1) (Expr.Num 2)) ↦* (Expr.Num 3) :=
  evals.Step
    (Expr.Binop Binop.Add (Expr.Num 1) (Expr.Num 2))
    (Expr.Num 3)
    (Expr.Num 3)
    (steps.DOp Binop.Add 1 2)
    (evals.Val (Expr.Num 3))

example : (Expr.Binop Binop.Add (Expr.Num 1) (Expr.Num 2)) ↦* (Expr.Num 3) := by
    apply evals.Step
    exact steps.DOp Binop.Add 1 2
    exact evals.Val (Expr.Num 3)

@[refl]
theorem evals_refl (e : Expr) : e ↦* e := evals.Val e

theorem evals_trans {e1 e2 e3 : Expr} (h1 : e1 ↦* e2) (h2 : e2 ↦* e3)
  : e1 ↦* e3 := by
    induction h1
    case Val => assumption
    case Step ih =>
      apply evals.Step
      assumption
      exact ih h2

-- @[trans] in Lean 3 is replaced by Trans typeclass
instance: Trans (α := Expr) (· ↦* ·) (· ↦* ·) (· ↦* ·) where
  trans := evals_trans

theorem transitive_left (b : Binop) (el el' er : Expr) :
  (el ↦* el') → (Expr.Binop b el er ↦* Expr.Binop b el' er) :=
  sorry -- Remove this line and add your proof

theorem transitive_right (b : Binop) (el er er' : Expr) :
  val el → (er ↦* er') → (Expr.Binop b el er ↦* Expr.Binop b el er') :=
  sorry -- Remove this line and add your proof
