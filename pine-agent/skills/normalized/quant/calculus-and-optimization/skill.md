# Skill: calculus-and-optimization

## Metadata

```yaml
id: calculus-and-optimization
name: Calculus & Optimization
version: 1.0.0
path: skills/normalized/quant/calculus-and-optimization/skill.md
layer: QUANT
domains: [mathematics, optimization]
triggers:
  english:
    - discrete derivative
    - rate of change
    - second derivative
    - discrete integral
    - trapezoidal integration
    - root finding
    - bisection
    - parameter optimization
    - saturation function
  persian:
    - حسابان گسسته
    - نرخ تغییر
    - انتگرال گسسته
    - یافتن ریشه
    - بهینه‌سازی پارامتر
dependencies:
  mandatory: []
  optional: [mathematical-foundation, numerical-methods, pine-performance-engineering, adaptive-systems]
status: normalized
priority: 2
```

## Purpose

Discrete derivatives/integrals, rate-of-change concepts, and optimization
strategies inside Pine's bar-sequential world — including the platform reality
that Pine has no solvers/gradients and optimization is analytic, offline, or
iteration-capped in-script.

## Triggers

Select for: momentum-as-derivative designs; curvature/acceleration detection;
windowed sums/areas under curves; root finding / level solving; parameter
search or "optimize this in Pine" requests; gradient-flavored adaptive logic.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Calculus/optimization need | description | formalization contract | yes |
| Noise level of target series | context | data characteristics | no |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Discrete operator mapping | knowledge applied | Implementation |
| Solver design with caps | implementation pattern | Implementation |
| "No in-script optimization" constraint | feasibility note | Feasibility |

## Rules

1. Derivatives (discrete): first difference `ta.change(x, 1) = x - x[1]`;
   N-bar rate of change `ta.change(x, n)` or `ta.roc(x, n)`; second derivative
   `ta.change(ta.change(x))` is noisy — smooth first (e.g., EMA) before
   differentiating; slope over window via `ta.linreg(src, len, 0) -
   ta.linreg(src, len, 1)` per bar, or regression endpoints
   `(linreg_now - linreg_n_bars_ago) / n`. (`ta.slope` does NOT exist —
   source-verified; compute via linreg differences.)
2. Integrals (discrete): cumulative `ta.cum(src)` from dataset start; windowed
   integral `math.sum(src, len)` (rolling); trapezoid refinement for
   price-like series `(y[i] + y[i+1]) / 2 * dt` summed in a loop;
   area-under-curve patterns (volume-weighted accumulations; VWAP as running
   ∫(price·volume)dV / ∫volume conceptually).
3. Limits & asymptotics: thresholds via `math.max/min`; saturation via clamps
   `math.max(0, math.min(1, score))`; exponential saturation
   `1 - math.exp(-k*x)` growth-to-limit shapes.
4. Optimization in Pine: NO general solvers/gradients. Options: (1) analytic
   closed forms (least squares via `ta.linreg` or matrix math); (2) grid/random
   search OFFLINE (TradingView's strategy-tester parameter optimizer is the UI
   tool; Pine does not self-optimize — one parameter set per run); (3) in-script
   iterative loops with convergence conditions and iteration caps (500 ms/bar
   budget) — e.g., bisection, Newton-style root finding with caps.
5. Gradient CONCEPTS for scoring: direction + magnitude of improvement
   (`dScore = score - score[1]`) for adaptive steps (see adaptive-systems).
6. Root-finding pattern (bounded bisection): bracket [lo, hi]; iterate with a
   hard cap (e.g., 60); halve by sign test `f(lo) * f(mid) <= 0`; converge to
   `(lo + hi) / 2`.

## Workflow

1. Translate the calculus concept to discrete operators (rules 1–2).
2. Smooth before differentiating noisy series (rule 1).
3. For solving, choose bisection/Newton/fixed-point with caps + fallbacks
   (rules 4, 6; see numerical-methods for stability details).
4. State explicitly that parameter optimization happens outside Pine (rule 4)
   whenever a user expects self-optimization.
5. Record loop budgets in Feasibility.

## Constraints

- All iterative methods require iteration caps (500 ms/bar).
- No in-script parameter optimization (one parameter set per run).
- `ta.slope` does not exist (rule 1).

## Assumptions

- Operator availability per v6 reference as claimed by the source.

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| Double-noise derivative | jumpy second derivative | rule 1: smooth first |
| Unbounded solver | 500 ms loop timeout | rule 6: iteration caps |
| Expected self-optimization | misunderstanding | rule 4: offline/UI optimization |
| math.sum vs ta.cum confusion | wrong accumulation | rule 2 semantics |

## Dependencies

Optional: mathematical-foundation (precedence/precision),
numerical-methods (stability/interpolation), pine-performance-engineering
(loop budgets), adaptive-systems (gradient-concept usage). Load only on their
own triggers.

## Examples

- "Measure acceleration of momentum" → rule 1 second derivative + smoothing.
- "Find where my score crosses 0.5" → rule 6 bounded bisection.
- Persian: «بهینه‌سازی خودکار داخل پاین ممکنه؟» → rule 4: no — offline/UI.

## Verification Criteria

- Derivatives computed from smoothed series where noise present.
- Every solver loop has a documented iteration cap.
- No reliance on non-existent APIs (`ta.slope`).
- Optimization expectations routed to offline/UI tooling.

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-002` import from `skills/incoming/18-calculus-and-optimization.md`.
- Structural reorganization only; no semantic changes. The source's own
  negative-claim corrections (`ta.slope` does not exist) preserved verbatim in
  meaning — negative claims are retained as verify-before-use gates like
  linear-algebra's do-not-exist list.

## Source Reference

- Original filename: `18-calculus-and-optimization.md`
- Original source path: `skills/incoming/18-calculus-and-optimization.md`
- Import batch: `batch-002`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-002)
