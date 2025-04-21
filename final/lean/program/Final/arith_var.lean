inductive Binop | Add | Sub | Mul | Div
example : Binop := Binop.Add


inductive Expr
| Num : Nat → Expr
| Binop : Binop → Expr → Expr → Expr
| Let : Expr → Expr → Expr
| Var : Nat → Expr

example : Expr := Expr.Num 1
example : Expr := Expr.Binop Binop.Add (Expr.Num 1) (Expr.Num 2)


inductive val : Expr → Prop
| DNat (n : Nat) : val (Expr.Num n)

example : val (Expr.Num 2) := val.DNat 2


def apply_binop (op : Binop) (nl nr : Nat) : Nat :=
  Binop.casesOn op (nl + nr) (nl - nr) (nl * nr) (nl / nr)

inductive subst : Nat → Expr → Expr → Expr → Prop
| SNum {i n : Nat} {e' : Expr} : subst i e' (Expr.Num n) (Expr.Num n)
| SBinop {op : Binop} {i : Nat} {el er el' er' e' : Expr} :
  subst i e' el el' → subst i e' er er' →
  subst i e' (Expr.Binop op el er) (Expr.Binop op el' er')
| SLet {i : Nat} {e' evar ebody evar' ebody' : Expr} :
  subst i e' evar evar' → subst (i + 1) e' ebody ebody' →
  subst i e' (Expr.Let evar ebody) (Expr.Let evar' ebody')
| SVarEq {i : Nat} {e' : Expr} :
  subst i e' (Expr.Var i) e'
| SVarNe {i j : Nat} {e' : Expr} :
  i > j → subst i e' (Expr.Var j) (Expr.Var j)

inductive steps : Expr → Expr → Prop
| DLeft (op : Binop) (el el' er : Expr) :
  steps el el' →
  steps
    (Expr.Binop op el er)
    (Expr.Binop op el' er)
| DRight (op : Binop) (el er er' : Expr) :
  steps er er' → val el →
  steps
    (Expr.Binop op el er)
    (Expr.Binop op el er')
| DOp (op: Binop) (nl nr : Nat) :
  steps
    (Expr.Binop op (Expr.Num nl) (Expr.Num nr))
    (Expr.Num (apply_binop op nl nr))
| DLet (evar ebody ebody' : Expr) :
  subst 0 evar ebody ebody' →
  steps (Expr.Let evar ebody) ebody'

notation:35 e " ↦ " e' => steps e e'

example : (Expr.Binop Binop.Add (Expr.Num 1) (Expr.Num 2)) ↦ (Expr.Num 3) :=
  steps.DOp Binop.Add 1 2

-- let 2 in ((var 0) + 3) ↦ 2 + 3
example : (Expr.Let (Expr.Num 2) (Expr.Binop Binop.Add (Expr.Var 0) (Expr.Num 3)))
            ↦ (Expr.Binop Binop.Add (Expr.Num 2) (Expr.Num 3)) := by
  apply steps.DLet
  apply subst.SBinop
  apply subst.SVarEq
  apply subst.SNum

inductive valid : Nat → Expr → Prop
| TNum {n ctx : Nat} :
  valid ctx (Expr.Num n)
| TBinop {op : Binop} {el er : Expr} {ctx : Nat} :
  valid ctx el → valid ctx er → valid ctx (Expr.Binop op el er)
| TLet {ctx : Nat} {evar ebody : Expr} :
  valid ctx evar → valid (ctx + 1) ebody → valid ctx (Expr.Let evar ebody)
| TVar {ctx i : Nat} :
  i < ctx → valid ctx (Expr.Var i)

theorem valid_in_bigger_context {e : Expr} {i : Nat} :
    valid i e → valid (i + 1) e := by
  intro hvalid
  induction hvalid
  case TNum => apply valid.TNum
  case TBinop hl hr ihl ihr =>
    apply valid.TBinop ihl ihr
  case TLet hvar hbody ihvar ihbody =>
    simp at ihbody
    apply valid.TLet ihvar ihbody
  case TVar ctx var ihle =>
    apply valid.TVar
    have h : ctx < ctx + 1 := by simp
    apply Trans.trans ihle h

theorem subst_preserves_valid {ebody evar esub : Expr} {ctx : Nat} :
    valid (ctx + 1) ebody → valid ctx evar → subst ctx evar ebody esub → valid ctx esub := by
  intro hvbody hvvar hsubst
  induction hsubst
  case SNum n => apply valid.TNum
  case SBinop hl hr ihl ihr =>
    apply valid.TBinop
    match hvbody with | valid.TBinop hl' _ => apply ihl hl' hvvar
    match hvbody with | valid.TBinop _ hr' => apply ihr hr' hvvar
  case SLet i e' _ _ _ _ hvar hbody ihvar ihbody =>
    apply valid.TLet
    match hvbody with | valid.TLet v _ => apply ihvar v hvvar
    match hvbody with
    | valid.TLet _ b =>
      apply ihbody b (valid_in_bigger_context hvvar)
  case SVarEq => apply hvvar
  case SVarNe =>
    apply valid.TVar
    assumption


theorem preservation :
    ∀ e e' : Expr, (e ↦ e') → valid 0 e → valid 0 e' := by
  intro e e' hstep hvalid
  cases e
  case Num n => contradiction
  case Binop op el er =>
    cases hstep
    case DLeft el' h =>
      apply valid.TBinop
      apply preservation el el' h
      match hvalid with | valid.TBinop h1 _ => exact h1
      match hvalid with | valid.TBinop _ h2 => exact h2
    case DRight er' v h =>
      apply valid.TBinop
      match hvalid with | valid.TBinop h1 _ => exact h1
      apply preservation er er' h
      match hvalid with | valid.TBinop _ h2 => exact h2
    case DOp nl nr => apply valid.TNum
  case Let evar ebody =>
    cases hstep
    case DLet hsubst =>
      apply subst_preserves_valid _ _ hsubst
      match hvalid with | valid.TLet _ b => exact b
      match hvalid with | valid.TLet v _ => exact v
  case Var i => contradiction
