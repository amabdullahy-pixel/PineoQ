---
name: probability
category: Statistics & Probability
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/pine-script-reference/v6/
  - https://www.tradingview.com/pine-script-docs/faq/functions/
---

# Probability

## Purpose
Probability theory applied to trading logic: conditional probability, expected
value, joint events, Bayes updating — implementable in Pine.

## When to Use
- Signal confidence scoring, win-rate reasoning, multi-condition filtering,
  belief updating from new evidence.

## Core Knowledge

### Conditional Probability
- P(A|B) = P(A∩B) / P(B), P(B) > 0.
- In Pine: estimate empirically from history:
```pine
var int nB = 0, var int nAB = 0
condB = ta.sma(close, 50) > ta.sma(close, 200)
condA = close > open
if condB
    nB += 1
    if condA
        nAB += 1
float pA_givenB = nB > 0 ? nAB / float(nB) : na
```
- Track joint event counts with var ints over a rolling or lifetime window.

### Expected Value & Conditional Expectation
- EV = Σ pᵢ·xᵢ. Trade EV = winRate·avgWin − (1−winRate)·avgLoss (skill 32).
- Conditional expectation in Pine: average of x where condition held (accumulate
  sum & count inside `if cond`).
- Decision rule: take setups only when EV > costs (commission+slippage share).

### Joint Probability & Independence
- P(A∩B) = P(A)·P(B) ONLY if independent. Correlated indicators do NOT give
  multiplicative confidence — overlapping conditions inflate naive scores.
- P(A∪B) = P(A)+P(B)−P(A∩B).
- Practical: for signal fusion, prefer empirical joint frequencies over
  independence assumptions (skill 46, Bayesian fusion).

### Bayes Theorem (belief updating)
- P(H|E) = P(E|H)·P(H) / P(E).
- Trading form: prior = base rate of setups winning; likelihood = how often
  this evidence appears among winners vs losers:
```pine
// odds form: posteriorOdds = priorOdds × likelihoodRatio
float lr = pE_givenWin / pE_givenLoss      // estimated from trade history
float postOdds = priorOdds * lr
float posterior = postOdds / (1 + postOdds)
```
- Multiple independent evidence pieces multiply their likelihood ratios
  (verify independence!).

### Probability Distributions (link to skill 23)
- Discrete outcomes of trades (win/loss, R-multiples) → empirical distribution
  stored in arrays; theoretical fits (normal/lognormal/t) only as approximations.

## Common Mistakes
- Multiplying P(A)·P(B) for highly correlated indicators (fake confidence boost).
- Estimating probabilities from tiny samples (<30 events) — report na instead.
- Ignoring base rates: a 90%-precise rare-condition filter can still be mostly wrong.
- Double-counting the same information in Bayesian updates (correlated evidence).

## Corrections & Updates
- [2026-09] Created; Pine counting patterns verified against docs/reference.
