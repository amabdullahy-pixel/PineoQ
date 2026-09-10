---
name: hypothesis-and-formula-engineering
category: Research & Modeling
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.getswoopr.com/stocks/backtesting/research-protocols-experiment-design/write-a-falsifiable-trading-hypothesis/
---

# Hypothesis & Formula Engineering

## Purpose
Generating testable hypotheses, deriving formulas, producing alternative
formulations, and analyzing assumptions.

## When to Use
- Converting an intuition/observation into a formal, testable model.

## Core Knowledge

### Hypothesis Template (fill ALL slots or it's not a hypothesis)
```
HYPOTHESIS: <mechanism sentence: WHY should this predict returns?>
SIGNAL:     <exact formula(s) — see alternative formulations>
UNIVERSE:   <symbol(s)/class>          TIMEFRAME: <tf>
PERIOD:     <pinned dates>             COSTS: <commission+slippage model>
METRIC:     <primary metric>           THRESHOLD: <pass value>
NEGATION:   <the observation that refutes it>
MECHANISM CLASS: microstructure / behavioral / flow / carry / momentum...
```
- Weak: "momentum works." Strong: "20-bar ROC z-score > 1 predicts h-bar
  forward return on BTCUSDT 1D 2019–2026, net 5bps+2bps; threshold: OOS
  expectancy > 2× costs, N ≥ 100; refuted if OOS ≤ 0."

### Formula Generation
- From mechanism → math: define state (x), normalization (skill 21), threshold
  family (fixed / percentile / regime-conditional, skill 48), horizon h.
- Dimension check: every term unitless or ATR-scaled; no raw-price additions
  across regimes (stationarity, skill 26).
- Cost-aware by construction: expected gross edge must plausibly exceed
  round-trip costs BEFORE testing (killing ideas cheaply).

### Alternative Formulations (anti-artifact guard — mandatory ≥3)
- Test the SAME concept in structurally different math:
  - Momentum: (a) ROC (b) z-scored ROC (c) percentrank of ROC.
  - Reversion: (a) z of price-to-VWAP (b) ATR distance (c) BB %B.
- Verdict rule: only if ≥2 formulations survive OOS → real phenomenon; one
  survivor = likely formula artifact.

### Assumption Analysis (each → failure mapping)
| Assumption | Breaks if… | Fails as |
|---|---|---|
| Fills at assumed price | gaps/illiquidity | inflated P&L (skill 09/51) |
| Costs constant | spread widens in stress | regime losses |
| Stationarity | regime shift | param decay (skill 47) |
| Independence of signals | correlation spikes | fused confidence fake (skill 22) |
| Liquidity capacity | size grows | impact costs (skill 57) |

## Common Mistakes
- Formula-first, mechanism-never (no WHY → cannot falsify meaningfully).
- One formulation only (artifact risk).
- Threshold chosen after seeing the distribution (preregister instead).
- Assumptions implicit; not mapped to failure modes.

## Corrections & Updates
- [2026-09] Created; template + formulation rule formalized.
