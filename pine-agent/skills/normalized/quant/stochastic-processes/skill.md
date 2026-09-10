# Skill: stochastic-processes

## Metadata

```yaml
id: stochastic-processes
name: Stochastic Processes
version: 1.0.0
path: skills/normalized/quant/stochastic-processes/skill.md
layer: QUANT
domains: [statistics, market-modeling]
triggers:
  english:
    - random walk
    - GBM simulation
    - Box-Muller
    - Markov chain states
    - martingale
    - mean reversion OU
    - half-life of reversion
    - Hurst exponent
  persian:
    - فرایندهای تصادفی
    - بازگشت به میانگین
    - زنجیره مارکوف
    - توان هورست
dependencies:
  mandatory: []
  optional: [monte-carlo-and-resampling, regression-correlation, time-series-analysis, statistical-arbitrage]
status: normalized
priority: 2
```

## Purpose

Random walks, Markov chains, martingales, mean reversion, and
Brownian-motion concepts as market-modeling and simulation foundations —
GBM/Box–Muller simulation idioms, transition-matrix estimation, OU
half-life math, and Hurst-style regime classification.

## Triggers

Select for: modeling price evolution for Monte Carlo; regime classification
(trend vs mean-reversion); spread/OU half-life estimation; risk-scenario
simulation; Markov-style regime-switch designs.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Modeling/simulation need | description | formalization contract | yes |
| Per-bar log-return stats (μ, σ) | computed inputs | statistics | yes |
| Transition/OU data sufficiency | context | data characteristics | no |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Simulation/regime model | implementation pattern | Implementation |
| Half-life / persistence estimates | design facts | Implementation Planning |
| √N noise-scaling warnings | warnings | Feasibility |

## Rules

1. Random walk & GBM (discrete, per-bar simulation): random walk
   Xₜ = Xₜ₋₁ + εₜ with i.i.d. εᵢ; GBM step dLogP = (μ − 0.5σ²) + σ·Z where
   Z ~ N(0,1) via Box–Muller from two `math.random` draws (seeded for
   reproducibility — see monte-carlo-and-resampling); simulate LOG steps, not
   arithmetic ones (lognormal drift correctness). Drift vs diffusion: over N
   bars, signal ≈ μ·N vs noise ≈ σ·√N — edges must scale with N to overcome
   √N noise.
2. Markov chains (regime models): discrete states (e.g., 0=down, 1=flat,
   2=up); estimate transition matrix P from history by counting transitions
   (var matrix or 3×3 array; P[i][j] = count(i→j)/rowSum(i)); uses — expected
   regime persistence, regime-switch forecasts, filter design; Markov
   property assumption (next state depends only on current) must be tested
   (lagged transitions residual dependence) before trusting higher-order
   claims.
3. Martingale vs mean reversion: martingale E[Xₜ₊₁ | history] = Xₜ (no
   exploitable drift); sub/super-martingales frame downside drift vs growth;
   mean reversion as OU-process flavor xₜ₊₁ = xₜ + κ(θ − xₜ) + σεₜ —
   simulate or fit by regressing Δx on x (slope ≈ −κ·dt, intercept ≈ κθ·dt;
   low R² is normal); half-life of reversion ≈ ln(2)/κ in bars — key for
   pair-trade horizons.
4. Trading applications: Hurst exponent (rescaled-range or variance-ratio
   method, manual loop) — H > 0.5 trending, H < 0.5 mean-reverting, H ≈ 0.5
   random walk; estimate on returns per regime window; z-score spread models
   assume OU dynamics — validate half-life before trading.

## Workflow

1. Characterize the series (Hurst/variance-ratio — see
   time-series-analysis) before choosing a model (rule 4).
2. For simulation: log-step GBM with seeded Box–Muller (rule 1); run within
   monte-carlo-and-resampling budget rules.
3. For regime models: build/validate transition matrices with sufficient
   counts (rule 2).
4. For spread trading: fit OU, compute half-life, validate before use
   (rules 3–4).

## Constraints

- √N noise scaling applies to every projection — no "expected profit" claims
  without it.
- Markov/OU assumptions must be validated, not presumed.

## Assumptions

- Simulation idioms use verified `math.random`/seed semantics (source-stated;
  consistent with monte-carlo-and-resampling).

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| Mean-reversion logic on trending series | H > 0.5 evidence | rule 4: classify first |
| Tiny-N transition matrices | rows from few events | rule 2: sufficiency checks |
| Arithmetic GBM steps | wrong lognormal drift | rule 1: log steps |
| Profit projections ignoring √N | fantasy targets | rule 1: noise scaling |

## Dependencies

Optional: monte-carlo-and-resampling (simulation harness/budget),
regression-correlation (OU fitting), time-series-analysis (regime
diagnostics), statistical-arbitrage (pair-trade consumers). Load only on
their own triggers.

## Examples

- "Simulate 1,000 equity paths" → rule 1 GBM + monte-carlo budget rules.
- "Half-life of my spread?" → rule 3 OU fit, ln(2)/κ.
- Persian: «مدل مارکوف رژیم بازار» → rule 2 with validation.

## Verification Criteria

- Series classified (Hurst/variance-ratio) before model choice.
- GBM uses log steps with seeded randomness; budget caps respected.
- Transition matrices have per-row sufficiency; Markov assumption tested.
- Half-life validated before z-score spread trading.

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-003` import from `skills/incoming/27-stochastic-processes.md`.
- Structural reorganization only; no semantic changes.

## Source Reference

- Original filename: `27-stochastic-processes.md`
- Original source path: `skills/incoming/27-stochastic-processes.md`
- Import batch: `batch-003`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-003)
