# Skill: technical-analysis-core

## Metadata

```yaml
id: technical-analysis-core
name: Technical Analysis Core
version: 1.0.0
path: skills/normalized/research/technical-analysis-core/skill.md
layer: RESEARCH
domains: [technical-analysis, indicator-design]
triggers:
  english:
    - five pillars of technical analysis
    - indicator classification
    - one indicator per pillar
    - redundant oscillators
    - which indicator should I use
    - combine indicators
  persian:
    - تحلیل تکنیکال
    - طبقه‌بندی اندیکاتورها
    - ترکیب اندیکاتورها
dependencies:
  mandatory: []
  optional: [trend-indicators, momentum-indicators, volatility-indicators, volume-analysis]
status: normalized
priority: 2
```

## Purpose

The five pillars (trend, momentum, volatility, volume, price action) as a
classification and combination discipline for building indicators in Pine —
what each pillar measures, which are built-in vs manual, and how to avoid
same-family redundancy.

## Triggers

Select for: designing any indicator/strategy; deciding what each component
contributes; "which indicator should I use?" questions; auditing redundant
indicator stacks; normalization choices across indicators.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Indicator/strategy design goal | description | user request | yes |
| Existing components | list | formalization contract | no |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Pillar classification of the design | design decision | Implementation Planning |
| Redundancy/anti-combo warnings | warnings | Pre-Verification |
| Built-in vs manual availability map | design facts | pillar skills |

## Rules

1. The five pillars and their questions: Trend (direction & persistence — MA
   family, ta.supertrend, ADX, structure); Momentum (speed of change,
   exhaustion — RSI, ROC/MOM, Stochastic, MACD hist); Volatility (dispersion
   of outcomes — ATR, BB, KC, HV manual); Volume (participation/conviction —
   volume, OBV, VWAP, RVOL manual); Price Action (raw structure — pivots,
   candles, levels manual).
2. Combination discipline: ONE indicator per pillar per signal — stacked
   momentum oscillators are redundant (high correlation, fake confirmation;
   see probability/signal-fusion); anti-constructive combos — momentum
   (mean-reverting flavor) inside strong trend filters: define regime first
   (see regime-detection), then choose pillar logic; normalize comparisons via
   z-scores/percentiles (see statistics-core/adaptive-systems), not raw values
   across symbols/timeframes.
3. Reference behavior notes: smoothed (RMA/EMA-based) indicators inherit
   warm-up bias — gate on `bar_index >= warmup` (see time-series-analysis);
   pivots confirm late by design (rightBars lag) — never real-time signals
   (see repainting-and-lookahead).
4. Built-in vs manual headline rules (details in pillar skills 35–39): KAMA,
   Donchian, HV, CVD, Volume Profile, candlestick patterns have NO built-ins;
   Supertrend direction convention is COUNTERINTUITIVE (see
   trend-indicators).

## Workflow

1. Classify the request into pillars (rule 1); map each to its skill.
2. Check the combination for same-family stacking and anti-constructive
   combos (rule 2); require regime-first design where flagged.
3. Set normalization expectations (rule 2) for any cross-indicator logic.
4. Route availability questions to the pillar skills' verified inventories
   (rule 4).

## Constraints

- This is a classification/discipline layer — it does not provide
  implementations (pillar skills do).
- One indicator per pillar per signal unless a documented justification
  exists.

## Assumptions

- Built-in availability claims verified by the source against the v6
  reference (consistent with the pillar skills' own verifications).

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| RSI+Stoch+CCI stack | one opinion ×3 | rule 2: one per pillar |
| Momentum signals inside strong trend filter | contradictory logic | rule 2: regime first |
| Raw-value comparison across assets | scale confusion | rule 2: z/percentile normalization |
| Defaults trusted blindly | unvalidated lengths | rule: revalidate per asset class |

## Dependencies

Optional: pillar skills (trend/momentum/volatility/volume/price-action),
regime-detection (regime-first design), statistics-core (normalization).
Load only on their own triggers.

## Examples

- "Add confirmation to my RSI entry" → rule 2: check pillar overlap first.
- "Why do my three momentum indicators agree/disagree together?" → rule 2
  redundancy.
- Persian: «چند اندیکاتور با هم بگذارم؟» → rule 2 discipline.

## Verification Criteria

- Design maps to pillars with one indicator per pillar (or documented
  exception).
- Regime context precedes oscillator logic where applicable.
- Normalization method stated for cross-indicator comparisons.
- Warm-up gating present on smoothed indicators.

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-004` import from `skills/incoming/34-technical-analysis-core.md`.
- Layer decision: RESEARCH (classification/design-discipline function, not
  implementation patterns) — establishes the `research/` layer directory.
- Structural reorganization only; no semantic changes.

## Source Reference

- Original filename: `34-technical-analysis-core.md`
- Original source path: `skills/incoming/34-technical-analysis-core.md`
- Import batch: `batch-004`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-004)
