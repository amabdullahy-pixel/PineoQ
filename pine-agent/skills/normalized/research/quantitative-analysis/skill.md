# Skill: quantitative-analysis

## Metadata

```yaml
id: quantitative-analysis
name: Quantitative Analysis
version: 1.0.0
path: skills/normalized/research/quantitative-analysis/skill.md
layer: RESEARCH
domains: [quant-methods, signal-design]
triggers:
  english:
    - alpha factor
    - factor normalization
    - composite score
    - information coefficient IC
    - rank IC
    - feature engineering
    - factor weighting
  persian:
    - تحلیل کمّی
    - فاکتور و آلفا
    - امتیاز ترکیبی
    - ضریب اطلاعات
dependencies:
  mandatory: []
  optional: [statistics-core, multi-symbol-engineering, time-series-analysis, walk-forward-and-validation]
status: normalized
priority: 2
```

## Purpose

Alpha signals, factor normalization, ranking, scoring, and the Information
Coefficient concept — quant pipeline thinking mapped to Pine's single-symbol
reality.

## Triggers

Select for: building composite indicators; signal scoring systems;
factor-style filters; IC/IR evaluation of a signal; normalization choices
before combining factors.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Factor/scoring requirement | description | formalization contract | yes |
| Horizon h (for IC tests) | parameter | user/formalization | yes |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Factor normalization/composite design | implementation pattern | Implementation |
| IC/IR evaluation plan | verification output | Post-Verification |
| Cross-sectional limits | feasibility notes | Feasibility |

## Rules

1. Alpha & factors: an alpha signal is any computed predictor of future
   relative returns (momentum, reversion, volume, structure); in
   single-symbol Pine, factors are TIME-SERIES (asset vs its own history);
   cross-sectional factors need multi-symbol requests (see
   multi-symbol-engineering) — Pine cannot rank a large universe efficiently
   in one script.
2. Signal normalization (the core discipline): z-score
   (x − sma)/stdev(x, len, false) (see statistics-core); rank
   `ta.percentrank(x, len)` ∈ [0,100] — robust to outliers; min-max window
   (x − lowest)/(range) with div-0 guard; ALWAYS normalize before combining
   factors with different units.
3. Composite scoring: score = Σ wᵢ·normFactorᵢ (e.g., momentum/participation/
   vol-alignment percentranks weighted 0.4/0.3/0.3 ∈ [0,100]); weights —
   equal start, change only with validation (see
   walk-forward-and-validation); fewer, DISTINCT factors > many correlated
   ones (see probability independence).
4. Information Coefficient: IC = corr(signal_t, return_{t→t+h}) over history;
   Pine proxy `ta.correlation(signal[shift], ta.change(close, h)[shift], N)`;
   Spearman-flavored (rank) IC preferred for fat tails — correlate
   percentranks; IR = mean(IC)/stdev(IC) — consistency of the signal, not
   one lucky period.
5. Feature-engineering hygiene: stationarize (returns/normalized scores,
   never raw prices — see time-series-analysis); warm-up gating; no
   lookahead — features built from `[1]`-confirmed data when feeding
   future-return tests (see repainting-and-lookahead).

## Workflow

1. Define factors explicitly; classify time-series vs cross-sectional
   feasibility (rule 1).
2. Normalize every factor before combination (rule 2).
3. Compose scores with documented weights (rule 3); keep factors distinct.
4. Evaluate with rank-IC/IR over non-overlapping, `[1]`-confirmed windows
   (rule 4–5).

## Constraints

- No raw-value factor averaging; no lookahead in IC tests.
- Cross-sectional ranking in one script is out of scope (request budget).

## Assumptions

- Normalization/IC patterns verified by the source vs reference + quant
  sources; single-symbol scope is Pine-native reality.

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| Unnormalized factor average | unit mixing | rule 2: normalize first |
| Momentum ×3 in disguise | correlated factors | rule 3: distinct families |
| Overlapping-return IC | inflated significance | rules 4–5: lag discipline |
| Universe ranking in one script | budget blowup | rule 1: multi-symbol design |

## Dependencies

Optional: statistics-core (z/percentrank tools),
multi-symbol-engineering (cross-sectional data), time-series-analysis
(stationarization), walk-forward-and-validation (weight validation). Load
only on their own triggers.

## Examples

- "Score momentum + participation + vol alignment" → rules 2–3 composite.
- "Is my signal predictive at all?" → rule 4 rank-IC/IR.
- Persian: «فاکتورها را چطور ترکیب کنم؟» → rule 2 normalization first.

## Verification Criteria

- Every factor normalized with a documented method.
- Composite weights documented and validated before tuning.
- IC tests use lagged, non-overlapping returns with warm-up gating.
- Rank-IC preferred for fat-tailed data.

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-005` import from `skills/incoming/44-quantitative-analysis.md`.
- No pending dependency pointers resolved by this skill (none referenced 44);
  new complementary relationships recorded with statistics-core
  (normalization tools) and signal-fusion (fusion consumers).
- Structural reorganization only; no semantic changes.

## Source Reference

- Original filename: `44-quantitative-analysis.md`
- Original source path: `skills/incoming/44-quantitative-analysis.md`
- Import batch: `batch-005`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-005)
