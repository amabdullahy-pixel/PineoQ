---
name: signal-fusion
category: Quantitative Trading
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/pine-script-reference/v6/
  - https://waylandz.com/quant-book-en/Lesson-09-Supervised-Learning-in-Quantitative-Trading/
---

# Signal Fusion

## Purpose
Combining multiple signals correctly: weighted voting, ensembles, confluence,
contradiction detection, hierarchical & Bayesian fusion.

## When to Use
- Any multi-indicator/multi-condition decision point.

## Core Knowledge

### Weighted Voting
```pine
float vote = 0.0
vote += wTrend * (trendUp ? 1 : trendDn ? -1 : 0)      // skill 40/47
vote += wMom   * (rsi > 50 ? 1 : -1)                    // skill 36
vote += wVol   * (rvol > 1.5 ? 1 : 0)                   // skill 38
bool longVote = vote >= longThreshold
```
- Votes must be INDEPENDENT-ish (distinct families, skill 22); correlated
  voters = hidden double-weighting. Cap total voters (3–6).

### Confluence (zone-based, not event-based)
- Confluence = independent evidence pointing at the same PRICE AREA: fib level
  + structure zone + VWAP band within tolerance (skill 42).
- Score by DISTINCT families; require spatial AND temporal alignment.

### Contradiction Detection
- Explicit conflict rules: momentum long while structure bear → NEUTRAL, not
  "average". Conflict = information: widen stop assumption or stand down.
- Contradiction table: {trend, momentum, volume, regime} pairwise conflicts
  enumerated at design time, not discovered live.

### Hierarchical Fusion
- Layer 1: regime gate (hard filter, skill 47) — no trade if wrong regime.
- Layer 2: strategy/structure layer (bias).
- Layer 3: trigger/timing layer. Higher layers VETO; lower layers never
  override higher layers.

### Bayesian Fusion (probability space, skill 22)
```pine
// posterior odds = prior odds × Π likelihood ratios (only independent evidence)
float lr1 = p(cond1 | win) / p(cond1 | loss)   // estimated from trade history
float lr2 = p(cond2 | win) / p(cond2 | loss)
float postOdds = priorOdds * lr1 * lr2
float confidence = postOdds / (1.0 + postOdds)
```
- Estimate likelihood ratios from ≥100 labeled historical events (arrays of
  outcomes, skill 28); correlated evidence breaks the multiplication.

## Common Mistakes
- Adding correlated votes (RSI+Stoch+CCI → momentum³).
- OR-ing weak conditions ("any of 5 triggers") instead of structured fusion.
- No contradiction policy → mixed signals executed anyway.
- Bayesian math on tiny samples.

## Corrections & Updates
- [2026-09] Created; fusion patterns verified vs quant sources/reference.
