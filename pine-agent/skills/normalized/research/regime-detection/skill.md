# Skill: regime-detection

## Metadata

```yaml
id: regime-detection
name: Regime Detection
version: 1.0.0
path: skills/normalized/research/regime-detection/skill.md
layer: RESEARCH
domains: [quant-methods, market-state]
triggers:
  english:
    - market regime classification
    - trending vs ranging
    - volatility regime percentile
    - Hurst variance ratio regime
    - transitional state
    - ADX threshold regime
  persian:
    - تشخیص رژیم بازار
    - رونددار یا رنج
    - رژیم نوسان
dependencies:
  mandatory: []
  optional: [market-structure, volatility-indicators, stochastic-processes, falsification-and-counterexamples]
status: normalized
priority: 1
```

## Purpose

Classifying market state (trend/range/volatility/transition) along orthogonal
axes to gate and parameterize strategies — before ANY mean-reversion vs trend
logic decision and for risk scaling.

## Triggers

Select for: regime gating of strategies; risk scaling by state;
trend/range/volatility classification; transitional-window handling;
"should this be a mean-reversion or trend system?" decisions.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Regime axes needed | list | formalization contract | yes |
| Threshold set (ADX, percentiles) | parameters | user (falsify per symbol) | yes |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Regime engine design | implementation pattern | Implementation |
| Regime state as gate input | contract field | signal-engineering, signal-fusion |
| Transitional-window rules | design output | Implementation |

## Rules

1. Regime dimensions (orthogonal axes, not one label): Direction (MA slope /
   structure trend — see market-structure: up/down/flat); Trendiness (ADX via
   ta.dmi, efficiency ratio — trending >25 / ranging <20 heuristics); 
   Volatility (ATR/BBW percentile — low/normal/high — see
   volatility-indicators); Persistence (Hurst/variance-ratio — mean-rev <0.5 /
   random / trend >0.5 — see stochastic-processes).
2. Pine regime engine (composite): ADX from ta.dmi(14,14); ATR percentile via
   ta.percentrank(ta.atr(14), 252); trending = adx > 25; highVol/lowVol =
   atrPct > 80 / < 20; direction via 50/200 SMA relation; momentum regime =
   trending AND normal vol; reversion regime = !trending AND lowVol.
3. Transitional state = recent regime change within N bars (regime !=
   regime[N]) → reduce size or stand down — regime flips are the
   highest-risk windows.
4. Volatility regimes: expansion = vol percentile rising fast (ATR percentile
   > 80 AND ATR slope > 0); contraction/squeeze = BBW/KCW percentile < 20 —
   pre-breakout posture; mean-reversion strategies belong in LOW-vol ranging;
   trend systems in trending + expanding.
5. Hurst/variance-ratio approximation: VR(k) = Var(k-bar returns)/(k·Var(1-bar
   returns)); VR > 1 trending, < 1 reverting; rolling window computed on
   RETURNS; re-estimate per regime window; low R² of OU fit (see
   stochastic-processes) = transitional.
6. Discipline: regime labels use CONFIRMED data (close-based — see
   repainting-and-lookahead); one strategy per regime envelope; no strategy
   "works everywhere"; ADX thresholds are asset-relative — normalize by
   percentile; thresholds are defaults to falsify per symbol (see
   falsification-and-counterexamples).

## Workflow

1. Choose the orthogonal axes for the use case (rule 1) — never a single
   label.
2. Build the composite engine with percentile-normalized thresholds
   (rule 2).
3. Implement transitional-state handling (rule 3).
4. Map strategy envelopes to regimes (rule 6); validate thresholds per
   symbol.

## Constraints

- No repainting regime flags (unconfirmed HTF data forbidden).
- No single-axis regime labels; no universal threshold claims.

## Assumptions

- Thresholds from quant practice sources — defaults to falsify per symbol
  (source-declared).

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| "Trending" label in high-vol chaos | single-axis label | rule 1/2: orthogonal axes |
| Whipsaw at regime flips | no transition handling | rule 3: stand-down window |
| ADX thresholds fail on low-vol assets | fixed cutoffs | rule 6: percentile normalization |
| Regime flags repaint | unconfirmed HTF | rule 6: confirmed data |

## Dependencies

Optional: market-structure (direction axis), volatility-indicators
(vol axis), stochastic-processes (persistence axis),
falsification-and-counterexamples (threshold falsification). Load only on
their own triggers.

## Examples

- "Only run my mean-reversion bot in quiet ranges" → rules 2, 4, 6.
- "Reduce size right after a regime flip" → rule 3.
- Persian: «استراتژی‌ام همه‌جا جواب نمی‌دهد» → rule 6: regime envelope.

## Verification Criteria

- Regime labels composite (≥2 axes) and confirmed-data based.
- Transitional window implemented with sizing/stand-down behavior.
- Thresholds percentile-normalized and falsified per symbol.
- Strategy-to-regime envelope documented.

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-005` import from `skills/incoming/47-regime-detection.md`.
- Resolves multiple pending optional-dependency pointers from batches 003/004
  (position-sizing, trade-management, technical-analysis-core,
  trend-indicators, momentum-indicators, market-structure — all listed
  regime-detection as a pending consumer).
- Structural reorganization only; no semantic changes.

## Source Reference

- Original filename: `47-regime-detection.md`
- Original source path: `skills/incoming/47-regime-detection.md`
- Import batch: `batch-005`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-005)
