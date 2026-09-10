# Skill: overfitting-and-robustness

## Metadata

```yaml
id: overfitting-and-robustness
name: Overfitting & Robustness
version: 1.0.0
path: skills/normalized/research/overfitting-and-robustness/skill.md
layer: RESEARCH
domains: [backtesting, robustness]
triggers:
  english:
    - curve fitting
    - overfitting
    - robustness battery
    - parameter stability
    - multiple testing false positive
    - trial ledger
  persian:
    - بیش‌برازش
    - استحکام استراتژی
    - منحنی برازش
dependencies:
  mandatory: []
  optional: [walk-forward-and-validation, monte-carlo-and-resampling,
    position-sizing, regime-detection, backtesting-science,
    pine-code-architecture]
status: normalized
priority: 1
```

## Purpose

Curve fitting, parameter stability, robustness across regimes/symbols/
timeframes, Monte Carlo robustness, and multiple-testing control — the final
gate before deploying or trusting any optimized strategy.

## Triggers

Select for: final gate before deploying/trusting an optimized strategy;
"why does it fail live?" post-mortems; multiple-testing audits; robustness
test design.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Optimized result | report | optimization run | yes |
| Trial ledger (K variants tested) | record | project memory | yes |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Robustness battery results | verification data | Post-Verification |
| Deployment verdict vs thresholds | gate decision | Post-Verification |
| K-adjusted significance requirements | statistical rule | statistical-testing |

## Rules

1. Curve fitting (definition + cure): overfit = model memorized noise —
   in-sample brilliance, OOS collapse. Cures: fewer parameters (see
   pine-code-architecture), longer samples, OOS discipline
   (walk-forward-and-validation), plateau-only acceptance
   (optimization-and-calibration), explicit falsification (see
   falsification-and-counterexamples).
2. Robustness battery (run ALL before trust): parameter stability —
   neighbors of chosen values must remain profitable (±20% on
   lookbacks/mults; sharp cliffs = noise); regime robustness — split by
   regime (see regime-detection): losing in one regime is acceptable ONLY IF
   regime-gated there; symbol robustness — same logic on 5+ related symbols,
   edge positive on most; timeframe robustness — 1–2 neighboring
   timeframes, fragile TF-lock = artifact; Monte Carlo robustness —
   bootstrap trade sequence (see monte-carlo-and-resampling): report 5th-
   percentile final equity and P(DD > X%), must survive the 5th-percentile
   path with the chosen position sizing (see position-sizing);
   sub-period consistency — 4+ equal sub-periods, one period carrying
   everything = fragility.
3. Multiple-testing control: K backtest variants tested → false-positive
   risk ≈ 1−(1−α)^K; budget trials; log EVERY variant tested (honest trial
   ledger); apply Bonferroni-style tightening — require OOS p < α/K
   conceptually, or demand larger effect sizes as K grows. Two independent
   OOS periods > one double-optimized parameter set.
4. Deployment thresholds (suggested defaults — falsify per system): ≥100
   trades, PF ≥ 1.3, expectancy > 2× costs, OOS retains ≥ 50% of IS
   expectancy, 5th-pct MC drawdown within risk policy.

## Workflow

1. Require the trial ledger before evaluating anything (rule 3).
2. Run the full robustness battery (rule 2).
3. Apply deployment thresholds (rule 4); record the verdict.
4. Failures route back: plateau discipline (rule 1) → re-fit or reject.

## Constraints

- A single great backtest is one draw from noise — never evidence alone.
- No robustness testing only on the winning symbol/TF.
- "It passed IS" is never the final word (IS is the EASY test).
- No trial ledger → unknowable K → unfalsifiable claims.

## Assumptions

- Thresholds are defaults to calibrate per market (source-declared).

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| Sharp parameter cliffs | instability | rule 2: neighborhood test |
| Unexplained regime loss | regime split | rule 2: gate or reject |
| Winning-symbol-only testing | selection | rule 2: 5+ symbols |
| Unknown K | no ledger | rule 3: ledger mandatory |

## Dependencies

Optional: walk-forward-and-validation (OOS discipline),
monte-carlo-and-resampling (bootstrap paths), position-sizing (5th-pct
survival check), regime-detection (regime splits), backtesting-science
(bias context), pine-code-architecture (fewer parameters). Load only on
their own triggers.

## Examples

- "Is my optimized strategy robust?" → rule 2 full battery.
- "I tested 40 variants" → rule 3 K-adjusted tightening.
- Persian: «چرا استراتژی‌ام لایو جواب نمی‌ده؟» → rule 1 overfit audit.

## Verification Criteria

- All six battery checks run and recorded.
- Trial ledger exists with K documented.
- Deployment verdict against thresholds recorded.
- OOS retention ≥ 50% of IS expectancy (or documented exception).

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-006` import from `skills/incoming/54-overfitting-and-robustness.md`.
- Resolves the batch-003 parked candidate {25↔54} (statistical-testing ↔
  overfitting: complementary — confirmed) and the registry pending
  optional-dependency pointers from statistical-testing and
  monte-carlo-and-resampling. Structural reorganization only; no semantic
  changes.

## Source Reference

- Original filename: `54-overfitting-and-robustness.md`
- Original source path: `skills/incoming/54-overfitting-and-robustness.md`
- Import batch: `batch-006`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-006)
