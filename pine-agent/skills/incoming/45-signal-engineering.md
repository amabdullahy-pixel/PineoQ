---
name: signal-engineering
category: Quantitative Trading
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://waylandz.com/quant-book-en/Lesson-09-Supervised-Learning-in-Quantitative-Trading/
  - https://www.tradingview.com/pine-script-reference/v6/
---

# Signal Engineering

## Purpose
Full signal lifecycle: generation → filtering → weighting → scoring →
confirmation → confidence → decay.

## When to Use
- Converting raw indicator events into robust, exec-ready signals.

## Core Knowledge

### Pipeline
```
Raw event → Noise filter → Normalize → Weight/Score → Confirm → Confidence → Decay → Output
```

### Generation & Filtering
- Raw events: crossovers, structure breaks, zone touches (skills 35–43).
- Noise filters: min displacement (body > k·avgBody), session gates (skill 14),
  volatility floor (ATR percentile > p), event-rate limiter (≥N bars between
  same-direction events: `bar_index - lastEventBar > cooldown`).

### Weighting & Scoring
- Score = Σ wᵢ·normFactorᵢ (skill 44); threshold on score, not raw events.
- Weights fixed per version — dynamic weights = adaptivity (skill 48) with
  overfitting tax (skill 54).

### Confirmation
- Bar close confirmation: `event and barstate.isconfirmed` (skill 07) or
  evaluate on `[1]`.
- Multi-bar confirmation: condition holds for K consecutive bars
  (`ta.barssince(not cond) >= K` pattern or counter var).
- MTF confirmation: HTF context agrees (skill 13, non-repaint pattern).

### Confidence Scoring
- Confidence = normalized confluence count (skill 46), regime agreement
  (skill 47), and sample-verified stats (skill 25) — NOT vibes.
- Gate execution: `if score > th and confidence > 0.6`.

### Signal Decay
- Stale signals lose edge: weight = exp(−λ·barsSinceTrigger),
  half-life = ln(2)/λ:
```pine
barsSince = bar_index - triggerBar
float w = math.exp(-math.log(2.0) * barsSince / halfLifeBars)
```
- Drop signals entirely after 3× half-life; track decay sensitivity in testing.

## Common Mistakes
- Firing signals intrabar without close confirmation (repaint).
- Hard thresholds never re-normalized across symbols/timeframes.
- No cooldown → signal storms in choppy tape.
- Treating confidence as binary; ignoring staleness.

## Corrections & Updates
- [2026-09] Created; Pine idioms verified vs reference.
