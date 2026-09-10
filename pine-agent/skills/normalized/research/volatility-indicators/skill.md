# Skill: volatility-indicators

## Metadata

```yaml
id: volatility-indicators
name: Volatility Indicators
version: 1.0.0
path: skills/normalized/research/volatility-indicators/skill.md
layer: RESEARCH
domains: [technical-analysis, volatility]
triggers:
  english:
    - ATR true range
    - Bollinger Bands bbw percentB
    - Keltner Channels squeeze
    - Donchian manual
    - historical volatility annualize
    - EWMA realized vol
  persian:
    - اندیکاتورهای نوسان
    - باند بولینگر
    - کانال دونچین
    - نوسان تاریخی
dependencies:
  mandatory: []
  optional: [technical-analysis-core, time-series-analysis, trade-management, falsification-and-counterexamples]
status: normalized
priority: 2
```

## Purpose

ATR, Bollinger, Keltner, Donchian, and historical/realized volatility —
verified forms and uses for stop/target sizing, regime detection,
squeeze/breakout logic, and normalization.

## Triggers

Select for: stop/target sizing inputs; regime/volatility-normalization
designs; squeeze/breakout logic; HV computations; "is squeeze → breakout
guaranteed?" audits.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Volatility-logic requirement | description | formalization contract | yes |
| Market calendar (annualization) | context | target symbol | yes |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Volatility implementation | knowledge applied | Implementation |
| Squeeze-determinism warnings | warnings | Pre-Verification |
| Regime normalization inputs | design facts | adaptive-systems |

## Rules

1. ATR: `ta.tr(true)` = max(h−l, |h−c[1]|, |l−c[1]|); `ta.atr(len)` =
   rma(tr, len) (Wilder smoothing — verified). Uses: stop distance (see
   trade-management), sizing (see position-sizing), regime z-scores of ATR
   (see regime-detection/adaptive-systems).
2. Bollinger Bands: `ta.bb(src, len, mult)` → [middle, upper, lower]; basis =
   SMA; bands = basis ± mult·stdev (population/biased default); `ta.bbw` =
   (upper−lower)/middle — squeeze = bbw percentile low; %B position
   (src − lower)/(upper − lower) is manual (guard division).
3. Keltner Channels: `ta.kc(src, len, mult, useTrueRange)` → [middle, upper,
   lower]; basis = EMA; envelope = ± mult·ATR (useTrueRange=true) or ±
   mult·(hi−lo); `ta.kcw` = width; BB-in-KC = classic squeeze (manual
   comparison).
4. Donchian: NO `ta.donchian` — manual ta.highest(high, len) /
   ta.lowest(low, len), mid = average; breakout logic
   `close > ta.highest(high, len)[1]` ([1] excludes the developing bar —
   prevents self-breaking; see price-action-patterns).
5. Historical/realized volatility (manual — no built-in HV): logR =
   log(close/close[1]); hvAnn = ta.stdev(logR, len)·sqrt(365)·100 for crypto
   (252 for equities); realVol = per-bar σ; EWMA forecast
   v := 0.94·v + 0.06·logR² via var recursion (see time-series-analysis).
6. Volatility regime notes: vol CLUSTERS (current vol predicts near-future
   vol) — normalize thresholds by vol regime (percentile of ATR/BBW);
   expanders = bbw/kcw percentile breakouts; contraction precedes expansion
   as a HEURISTIC — falsify per symbol, not a law (see
   falsification-and-counterexamples).

## Workflow

1. Choose the tool per use: sizing/stops → ATR (rule 1); bands/squeeze →
   BB/KC (rules 2–3); breakout ranges → manual Donchian (rule 4);
   vol modeling → HV/EWMA on log returns (rule 5).
2. Compute HV from returns, never prices (rule 5; stationarity —
   time-series-analysis).
3. Normalize all thresholds by vol regime percentiles (rule 6).
4. Guard zero-width divisions (rules 2–4; numerical-methods).

## Constraints

- No built-in HV or Donchian — manual implementations required.
- Squeeze → breakout direction is readiness, not determinism.

## Assumptions

- Formulas/defaults verified against reference/support articles by the source
  (ATR and HV support articles cited); annualization constants market-matched
  (365 crypto / 252 equities, consistent with financial-mathematics).

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| Squeeze direction traded as certain | deterministic assumption | rule 6: heuristic, falsify per symbol |
| stdev on prices for HV | non-stationary input | rule 5: log returns |
| Mixed ATR conventions | inconsistent sizing | rule 1: revalidate mults |
| bbw/kcw zero division | inf/nan | rules 2–4 guards |

## Dependencies

Optional: technical-analysis-core (pillar context), time-series-analysis
(clustering/EWMA), trade-management (stop consumers),
falsification-and-counterexamples (heuristic falsification). Load only on
their own triggers.

## Examples

- "Build a squeeze scanner" → rules 2–3 bbw/kcw percentiles.
- "Annualize realized vol for crypto" → rule 5 with 365.
- Persian: «فشردگی بولینگر یعنی حتماً حرکت بزرگ؟» → rule 6: only readiness.

## Verification Criteria

- ATR/bands built from verified forms; HV from log returns.
- Breakout comparisons exclude the current bar ([1]).
- Zero-width guards present; thresholds regime-normalized.
- Squeeze logic documented as heuristic with per-symbol falsification notes.

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-004` import from `skills/incoming/37-volatility-indicators.md`.
- Layer decision: RESEARCH (consistent with the TA block). Resolves the
  batch-003 pending pointer from time-series-analysis. Structural
  reorganization only; no semantic changes.

## Source Reference

- Original filename: `37-volatility-indicators.md`
- Original source path: `skills/incoming/37-volatility-indicators.md`
- Import batch: `batch-004`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-004)
