# Skill: adaptive-systems

## Metadata

```yaml
id: adaptive-systems
name: Adaptive Systems
version: 1.0.0
path: skills/normalized/research/adaptive-systems/skill.md
layer: RESEARCH
domains: [quant-methods, adaptivity]
triggers:
  english:
    - adaptive thresholds percentile
    - dynamic lookback
    - volatility normalization
    - regime-dependent parameters
    - KAMA efficiency ratio
    - adaptive overfitting
  persian:
    - سیستم‌های تطبیقی
    - آستانه‌های داینامیک
    - نرمال‌سازی نوسان
dependencies:
  mandatory: []
  optional: [regime-detection, trend-indicators, statistics-core, walk-forward-and-validation]
status: normalized
priority: 2
```

## Purpose

Adaptive thresholds, dynamic parameters/lookbacks, volatility normalization,
percentile thresholds, and regime-dependent parameter sets — for systems that
must survive changing volatility/regimes without manual retuning, with
explicit anti-overfitting discipline.

## Triggers

Select for: percentile-based thresholds; volatility-scaled lookbacks;
regime-dependent parameter switching; "make my indicator adaptive" requests;
auditing runaway adaptation.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Adaptivity requirement | description | formalization contract | yes |
| Baseline (fixed-param) version | artifact | current system | yes |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Adaptive mechanism design | implementation pattern | Implementation |
| OOS comparison requirement | verification gate | Post-Verification |
| Clamp/bound requirements | constraint notes | Pre-Verification |

## Rules

1. Adaptive thresholds (percentile-based): e.g., dynamic overbought =
   `ta.percentile_nearest_rank(rsi, 250, 95)`; static 70/30 lines assume a
   stable distribution — percentile thresholds auto-adapt per symbol/vol
   regime; window ≥ ~1 year of bars.
2. Dynamic parameters & lookbacks: lookback ∝ volatility —
   `len = max(10, round(baseLen · medVol/curVol))` (curVol = ATR ratio):
   longer in quiet, shorter in wild markets; KAMA-style adaptation —
   ER = |net move| / Σ|moves| (manual KAMA — see trend-indicators), ER→1 fast
   (trend), ER→0 slow (chop); one adaptation variable (ER) can drive
   thresholds, cooldowns, and score weights.
3. Volatility normalization: normalize ALL comparisons by vol — z-scores of
   ATR-scaled distances ((price − level)/ta.atr(14)), vol-normalized returns
   (see time-series-analysis), RVOL participation (see volume-analysis);
   raw-price thresholds break across regimes.
4. Regime-dependent parameter sets: discrete parameter switching per regime
   (see regime-detection) beats continuous chaos; parameter COUNT = the
   overfitting surface (see overfitting-and-robustness) — switch FEW
   parameters.
5. Anti-overfitting rules for adaptivity: adaptive ≠ better by default —
   every adaptive mechanism adds degrees of freedom; validate fixed-param
   baseline vs adaptive version OUT-OF-SAMPLE (see
   walk-forward-and-validation) — adaptive must beat baseline OOS to earn its
   complexity; BOUND all adaptive values (math.max/min clamps) — runaway
   adaptation (lookback → 3) is a silent failure.
6. Numerical care: adaptive lookback changing every bar is numerically
   unstable — smooth the adaptation variable first (EMA of the ratio);
   percentile thresholds on tiny windows are meaningless; unbounded adaptive
   state risks 500 ms loops or degenerate params.

## Workflow

1. Start from a fixed-param baseline; identify which parameters genuinely
   need adaptation (rule 5).
2. Choose the adaptation variable (percentile window, ER, vol ratio — rules
   1–3) and smooth it (rule 6).
3. Bound everything (rule 5); switch few parameters per regime (rule 4).
4. Validate adaptive vs baseline OOS before adopting (rule 5).

## Constraints

- No unbounded adaptive values; no per-bar adaptation-variable jumps.
- Adaptivity must earn its complexity via OOS comparison.

## Assumptions

- KAMA/ER and percentile patterns verified by the source vs
  sources/reference (ChartSchool KAMA, quant regime material).

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| Lookback oscillates every bar | instability | rule 6: smooth the ratio |
| Tiny-window percentiles | meaningless thresholds | rule 1: ≥1yr windows |
| Runaway adaptation | degenerate params/loops | rule 5: clamps |
| Adaptive complexity with no OOS gain | wasted degrees of freedom | rule 5: baseline comparison |

## Dependencies

Optional: regime-detection (regime-dependent sets), trend-indicators (ER/
manual KAMA), statistics-core (percentile tools),
walk-forward-and-validation (OOS validation). Load only on their own
triggers.

## Examples

- "Dynamic RSI overbought per symbol" → rule 1 percentile threshold.
- "My lookback explodes in crashes" → rules 5–6 clamps + smoothing.
- Persian: «اندیکاتورم خودش با نوسان تنظیم شود» → rules 1–3 with bounds.

## Verification Criteria

- All adaptive values clamped; adaptation variable smoothed.
- Percentile windows ≥ ~1 year of bars.
- Parameter-switch count minimized; OOS comparison vs fixed baseline recorded.
- Normalization applied to all cross-regime comparisons.

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-005` import from `skills/incoming/48-adaptive-systems.md`.
- Resolves the pending optional-dependency pointers from calculus-and-
  optimization (batch-002) and technical-analysis-core (batch-004).
- Structural reorganization only; no semantic changes.

## Source Reference

- Original filename: `48-adaptive-systems.md`
- Original source path: `skills/incoming/48-adaptive-systems.md`
- Import batch: `batch-005`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-005)
