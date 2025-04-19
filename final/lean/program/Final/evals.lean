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
    -- Currying: we can prove `(e2 ↦* e3) → (e1 ↦* e3)` given `h1: e1 ↦* e2`
    -- Doing structural induction over `h1`
    induction h1
    -- Base case: `e1 = e2`, then `h2` is what we want to prove
    case Val => assumption
    -- Inductive case: `e1 ↦* e2` because `(e1 ↦ e_step)` and `e_step ↦* e2`
    -- Inductive hypothesis (`ih`) is `(e2 ↦* e3) → (e_step ↦* e3)`
    case Step ih =>
      apply evals.Step  -- there must be steps from `e1` to `e3`
      -- `evals.Step` creates goals `e1 ↦ e_step` and `e_step ↦* e3`
      assumption  -- `e1 ↦ e_step`
      exact ih h2 -- `e_step ↦* e3`

-- @[trans] in Lean 3 is replaced by Trans typeclass
instance: Trans (α := Expr) (· ↦* ·) (· ↦* ·) (· ↦* ·) where
  trans := evals_trans

theorem transitive_left (b : Binop) (el el' er : Expr) :
  (el ↦* el') → (Expr.Binop b el er ↦* Expr.Binop b el' er) := by
    intro h
    induction h
    case Val => rfl
    case Step ih =>
      apply evals.Step
      apply steps.DLeft -- uses `el ↦* e_step` to create `Expr.Binop b el er ↦ Expr.Binop b e_step er`
      assumption        -- `el ↦* el'`
      exact ih

theorem transitive_right (b : Binop) (el er er' : Expr) :
  val el → (er ↦* er') → (Expr.Binop b el er ↦* Expr.Binop b el er') := by
    intro hval -- `val el`
    intro h
    induction h
    case Val => rfl
    case Step ih =>
      apply evals.Step
      apply steps.DRight -- similar to DLeft, but requires `val el`
      assumption
      exact hval
      exact ih
