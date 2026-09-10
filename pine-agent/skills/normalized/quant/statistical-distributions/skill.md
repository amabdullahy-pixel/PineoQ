# Skill: statistical-distributions

## Metadata

```yaml
id: statistical-distributions
name: Statistical Distributions
version: 1.0.0
path: skills/normalized/quant/statistical-distributions/skill.md
layer: QUANT
domains: [statistics, distribution-modeling]
triggers:
  english:
    - normal distribution
    - log-normal
    - student-t fat tails
    - skewness kurtosis
    - normal CDF erf
    - probit inverse normal
    - tail risk
  persian:
    - توزیع نرمال
    - دنباله‌های کلفت
    - چولگی و کشیدگی
    - توزیع‌های آماری
dependencies:
  mandatory: []
  optional: [statistics-core, monte-carlo-and-resampling, statistical-testing, numerical-methods]
status: normalized
priority: 2
```

## Purpose

Normal, log-normal, Student-t, fat tails, skew/kurtosis — properties and Pine
implementations. Built around one critical platform fact: Pine has NO built-in
erf/erfc/normal-CDF/quantile functions — approximations (Abramowitz–Stegun
erf, Acklam probit) must be implemented manually.

## Triggers

Select for: band construction from distribution assumptions; tail-risk
estimates; return modeling; Monte Carlo assumptions; "is my indicator assuming
normality?" audits; σ-threshold tail diagnostics.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Distribution question / band design | description | formalization contract | yes |
| Return-series character (tails) | context | data characteristics | no |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Distribution choice + approximation code plan | design decision | Implementation |
| Fat-tail warnings | warnings | Pre-Verification, risk-management |
| Tail diagnostic (empirical vs normal) | verification check | Post-Verification |

## Rules

1. Critical fact: Pine has NO built-in erf/erfc/normal-CDF/quantile functions.
   Implement via standard approximations — normal CDF from erf
   (Abramowitz–Stegun, |ε| < 1.5e-7, Horner-nested polynomial;
   `normCdf(x) = 0.5 * (1 + erf(x / sqrt(2)))`); inverse normal (probit) via
   Acklam rational approximation (for MC VaR); t-distribution — for df>30 use
   normal, lower df → Cornish–Fisher expansion or precomputed critical-value
   tables.
2. Families and uses: Normal (symmetric, thin tails — short-horizon returns
   approximation, Bollinger logic); Log-normal (positive-only, right skew —
   prices, compounded returns); Student-t (heavier tails, df-controlled —
   daily returns, robust CIs; df≈3–6 often fits daily returns far better than
   normal); Empirical (whatever the data says — ALWAYS validate against actual
   data first).
3. Moments beyond mean/variance: skewness Σ(x−x̄)³/σ³ and kurtosis
   Σ(x−x̄)⁴/σ⁴ (excess = kurt−3) computed via manual loops; financial returns
   typically show excess kurtosis > 0 (fat tails) → normal-based σ thresholds
   UNDERSTATE tail risk.
4. Fat-tail practical rules: percentile bands or robust MAD-based z (see
   statistics-core) instead of pure σ bands; prefer historical
   simulation/bootstrap over parametric VaR; run the stable-vs-normal
   diagnostic — compare actual % of |z|>3 events vs the 0.27% normal
   expectation.
5. Approximation integrity: wrong Horner nesting silently corrupts erf/erfc
   results — implementations must be verified against known values at
   Pre-Verification.

## Workflow

1. Test the distribution assumption against the actual data first (rule 2/4
   diagnostic).
2. If tails are fat, switch to percentile/robust-band designs (rule 4).
3. When CDF/quantile values are required, implement the approximations with
   verified nesting (rules 1, 5).
4. Feed tail-risk findings into risk-management and monte-carlo choices.

## Constraints

- No built-in distribution functions exist — every CDF/quantile is a manual
  approximation with stated error bounds.
- Normal-based σ thresholds must not be used for tail risk on fat-tailed
  returns.

## Assumptions

- Approximation constants (Abramowitz–Stegun, Acklam) are the standard
  published values as claimed by the source.

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| σ-multiple stops too tight | stops hit by normal noise | rule 4: fat-tail aware design |
| Wrong erf nesting | silently wrong CDFs | rule 5: verify against known values |
| Normal quantiles for small-N CIs | wrong coverage | rule 1: t-tables / df handling |
| Log-normal fit to jumpy prices | regime breaks | rule 2: validate empirically first |

## Dependencies

Optional: statistics-core (robust stats), monte-carlo-and-resampling (VaR
simulation consumers), statistical-testing (CI consumers),
numerical-methods (stability of manual loops). Load only on their own
triggers.

## Examples

- "Why do my 3σ bands get hit constantly?" → rule 4: fat tails; switch bands.
- "Compute P(X < x) in Pine" → rule 1 erf/normCdf implementation.
- Persian: «چرا حد ضرر ۳ انحرافی‌ام کم می‌آورد؟» → rule 4.

## Verification Criteria

- Any normality assumption is tested (|z|>3 diagnostic) before use.
- Manual erf/probit implementations verified against known values.
- Tail-risk logic does not rely on pure σ thresholds for fat-tailed data.
- Distribution choice documented with its validation evidence.

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-003` import from `skills/incoming/23-statistical-distributions.md`.
- The "no built-in distribution functions" claim is a negative claim —
  preserved as a verify-before-use gate per established convention (same
  treatment as linear-algebra's do-not-exist list and `ta.slope`).
- Structural reorganization only; no semantic changes.

## Source Reference

- Original filename: `23-statistical-distributions.md`
- Original source path: `skills/incoming/23-statistical-distributions.md`
- Import batch: `batch-003`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-003)
