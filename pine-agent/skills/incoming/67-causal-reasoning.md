---
name: causal-reasoning
category: Research & Modeling
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://en.wikipedia.org/wiki/Granger_causality
  - https://en.wikipedia.org/wiki/Bradford_Hill_criteria
  - https://www.investopedia.com/terms/c/correlation.asp
---

# Causal Reasoning

## Purpose
Correlation vs causation, confounding, spurious correlation, causal
hypotheses, and the limits of causal claims in market data.

## When to Use
- Every "X causes Y" claim in research notes; every intermarket filter design.

## Core Knowledge

### The Core Distinctions
- Correlation = co-movement. Causation = intervention would change the outcome.
- Spurious correlation base rate: test N random series at α →
  P(≥1 false find) = 1−(1−α)^N → ~1 as N grows (data mining, skill 25/54).
- Confounder Z drives both X and Y: e.g., BTC–Nasdaq correlation via global
  liquidity Z. When Z flips, the X→Y "link" vanishes — trade the Z-state, not
  the pair (regime conditioning, skill 47).

### Granger Causality (predictive precedence, NOT causation)
- X Granger-causes Y if past X improves forecasts of Y beyond Y's own lags.
- Implementable sketch (Pine): nested rolling OLS — restricted: y on y-lags;
  unrestricted: + x-lags; compare via F-test approximation or SSE reduction
  with preregistered thresholds (small-sample caution, skill 25).
- Limits: common drivers with different lags produce Granger "causation" with
  no structural link; nonlinearity breaks it; reflexive systems (skill below)
  violate its assumptions.

### Evidence Grading (Bradford Hill, adapted to trading)
- Strength (effect size) · Consistency (across regimes/symbols, skill 54) ·
  Specificity (predicts what it claims, not everything) · Temporality (signal
  at t from data ≤t, outcome t+h — the repaint law, skill 12) · Dose–response
  (stronger signal → larger effect; test via signal buckets) · Plausibility (a
  mechanism: flow, inventory, funding, liquidation mechanics) · Coherence
  (fits known market structure, skill 57) · Analogy (known relatives).
- Score hypotheses on these axes BEFORE backtesting; low-plausibility +
  high-backtest = data mining until proven otherwise.

### Market-Specific Causal Limits (assume always)
- No controlled experiments — observational only; everything is conditional.
- Non-stationarity: "causal" links decay with regimes (skill 47).
- Reflexivity: participants adapt; crowded signals alter the dynamics they
  exploit (edges self-destruct — monitor live vs backtest drift, skill 51).
- Post-hoc narrative risk: story-after-data is storytelling (HARKing, skill 62
  preregistration is the antidote).

### Language Discipline
- Say "X predicts Y in-sample on Z universe, mechanism hypothesized: M" —
  never "X causes Y" from backtests alone.

## Common Mistakes
- Intermarket filters built on raw correlation across regimes (skill 56 note).
- Reading Granger results as structural causation.
- Plausibility stories invented AFTER the backtest (preregister mechanisms).
- Ignoring reflexivity in crowded signals (funding/positioning proxies, skill 60).

## Corrections & Updates
- [2026-09] Created; definitions verified vs reference/encyclopedic sources.
