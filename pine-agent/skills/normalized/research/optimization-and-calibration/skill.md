# Skill: optimization-and-calibration

## Metadata

```yaml
id: optimization-and-calibration
name: Optimization & Calibration
version: 1.0.0
path: skills/normalized/research/optimization-and-calibration/skill.md
layer: RESEARCH
domains: [backtesting, optimization]
triggers:
  english:
    - parameter optimization
    - grid search random search
    - sensitivity analysis
    - parameter plateau
    - calibration vs optimization
    - no built-in optimizer
  persian:
    - بهینه‌سازی پارامتر
    - تحلیل حساسیت
    - کالیبراسیون
dependencies:
  mandatory: []
  optional: [overfitting-and-robustness, walk-forward-and-validation,
    pine-code-architecture, pine-version-intelligence]
status: normalized
priority: 1
```

## Purpose

Parameter optimization, grid/random search, sensitivity analysis, and
calibration — within TradingView's ACTUAL toolset (manual sweeps; no native
optimizer).

## Triggers

Select for: tuning inputs honestly; deciding whether a parameter even
matters; sensitivity/plateau analysis; "optimize my strategy" requests.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Parameter set to tune | list | current system | yes |
| Evaluation window (IS) | period | walk-forward scheme | yes |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Sweep protocol + log table | method | Implementation/user |
| Sensitivity (plateau) verdict | analysis | Post-Verification |
| Calibration choices | parameters | Implementation |

## Rules

1. Platform reality (verified): TradingView has NO built-in strategy
   parameter optimizer (three independent doc checks found none; such
   optimizers exist on MetaTrader, NOT TradingView; community feature
   requests ask for one). External automation tools violate TradingView ToS
   (account-ban risk). Therefore: optimization = MANUAL parameter sweeps
   (edit input → rerun → record) or in-script design that avoids sweeps.
2. Manual sweep discipline: sweep ONE parameter at a time; hold others
   fixed; log a table {param, value, netProfit, PF, maxDD, N trades}. Grid
   concept: 3–5 values per parameter spanning ≥2× range (e.g., ATR mult
   1.5/2/2.5/3/4). Random-search concept: random combos often beat full
   grids under a fixed trial budget (curse of dimensionality: k params × 5
   values = 5^k runs).
3. Sensitivity analysis (the real deliverable): GOOD = performance changes
   smoothly and stays positive across a NEIGHBORHOOD of values ("flat
   plateau"); BAD = sharp peak — performance collapses one step away →
   fitted noise (see overfitting-and-robustness). A parameter that must be
   "exactly 17" is not a parameter, it's a curve-fit. Decision rule: keep a
   parameter only if the plateau median beats the baseline.
4. Calibration vs optimization: calibration = setting FEW parameters to
   asset-class-sensible values (e.g., ATR mult 2–3, cost model to broker
   reality) — low degrees of freedom; optimization = SEARCH for best values
   — high degrees of freedom, always paired with OOS validation
   (walk-forward-and-validation). In-script reality: Pine runs ONE
   parameter set per execution; no auto-search inside a script; design
   fewer, meaningful inputs (see pine-code-architecture).

## Workflow

1. Decide calibration (few sensible values) vs optimization (search) for
   each parameter (rule 4).
2. If optimizing: one-parameter-at-a-time manual sweep with a logged table
   (rule 2).
3. Accept from plateaus only (rule 3); reject sharp peaks.
4. Validate accepted values OOS before adoption (rule 4 →
   walk-forward-and-validation).

## Constraints

- No sweeping 5+ parameters simultaneously (combinatorial explosion, all
  noise).
- Never optimize ON the evaluation window (leakage).
- Never report the best run instead of the plateau.
- No external auto-optimizers on the account (ToS risk).

## Assumptions

- No-built-in-optimizer finding verified 3× by the source (needs-review
  flag: re-verify if TradingView ships one — check release notes via
  pine-version-intelligence).

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| Simultaneous 5-param sweep | noise results | rule 2: one at a time |
| Best-run reporting | sharp peak | rule 3: plateau only |
| Optimization on eval window | leakage | rule 2/4: split first |
| External optimizer used | ToS risk | rule 1: manual only |

## Dependencies

Optional: overfitting-and-robustness (peak = noise discipline),
walk-forward-and-validation (OOS pairing), pine-code-architecture
(fewer meaningful inputs), pine-version-intelligence (re-verify flag).
Load only on their own triggers.

## Examples

- "Which ATR multiple should I use?" → rule 3 plateau sweep.
- "Can Pine auto-optimize inputs?" → rule 1: no — manual sweeps.
- Persian: «پارامترها رو چطور تنظیم کنم؟» → rules 2–3 sweep + plateau.

## Verification Criteria

- Sweep protocol logged (table of variants).
- Acceptance from plateaus, never peaks.
- Accepted parameters validated OOS.
- Calibration/optimization distinction documented.

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope (needs-review: platform optimizer status may
  change — gated by pine-version-intelligence re-verification).

## Import Notes

- Batch `batch-006` import from `skills/incoming/52-optimization-and-calibration.md`.
- Source self-declares confidence=medium with an explicit needs-review flag
  on the no-built-in-optimizer finding — preserved as a designed re-check
  gate, not silently resolved.
- Resolves the batch-002 parked candidate {18↔52} (calculus-and-optimization
  ↔ optimization-and-calibration: complementary, no_action → now recorded
  resolved). Structural reorganization only; no semantic changes.

## Source Reference

- Original filename: `52-optimization-and-calibration.md`
- Original source path: `skills/incoming/52-optimization-and-calibration.md`
- Import batch: `batch-006`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-006)
