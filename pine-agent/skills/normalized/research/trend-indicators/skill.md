# Skill: trend-indicators

## Metadata

```yaml
id: trend-indicators
name: Trend Indicators
version: 1.0.0
path: skills/normalized/research/trend-indicators/skill.md
layer: RESEARCH
domains: [technical-analysis, trend]
triggers:
  english:
    - moving average family
    - EMA vs RMA Wilder
    - HMA formula
    - ALMA parameters
    - supertrend direction sign
    - ADX DMI
    - KAMA manual implementation
    - MA crossover lag
  persian:
    - اندیکاتورهای روند
    - میانگین متحرک
    - سوپرترند
    - شاخص جهت‌دار ADX
dependencies:
  mandatory: []
  optional: [technical-analysis-core, repainting-and-lookahead, regime-detection, optimization-and-calibration]
status: normalized
priority: 2
```

## Purpose

The MA family and directional systems with verified v6 signatures and
formulas — including the two famous traps: `ta.kama` DOES NOT EXIST (manual
reference implementation provided) and Supertrend's counterintuitive
direction sign.

## Triggers

Select for: trend filters, regime classification, crossover systems, dynamic
levels; any MA-family signature/formula question; supertrend/ADX usage;
KAMA requirements.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Trend-logic requirement | description | formalization contract | yes |
| Asset class (length tuning) | context | data characteristics | no |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Correct MA/directional implementation | knowledge applied | Implementation |
| Sign/lag/availability warnings | warnings | Pre-Verification |
| Regime inputs (ADX, supertrend) | design facts | regime-detection |

## Rules

1. MA family (v6 verified): `ta.sma` arithmetic mean; `ta.ema` α = 2/(len+1)
   recursive; `ta.rma` α = 1/len (Wilder; ≡ EMA of length 2L−1); `ta.wma`
   linear weights len..1; `ta.vwma` = sma(src·vol)/sma(vol); `ta.hma` =
   wma(2·wma(src, len/2) − wma(src, len), √len); `ta.alma(src, len, offset,
   sigma, floor=false)` — Gaussian-weighted, offset shifts kernel center
   (smoothness↔responsiveness), sigma = width, optional floor bool (5th
   param CORROBORATED at import via a detailed v6-labeled reference listing;
   the 4-argument form remains unconditionally safe); `ta.swma(src)` fixed
   4-bar weights 1:2:2:1 ÷ 6, NO length param; **ta.kama DOES NOT EXIST** —
   implement manually (efficiency-ratio + smoothing-constant recursion per the
   source's reference implementation).
2. Directional systems: MACD `ta.macd(src, fast, slow, signal)` →
   [macd, signal, hist] (12/26/9 classic); DMI/ADX
   `ta.dmi(diLen, adxSmooth)` → [+DI, −DI, ADX] with Wilder smoothing
   (ADX>25 trending heuristic — regime input); Supertrend
   `ta.supertrend(factor, atrPeriod)` → [st, direction] with **direction = −1
   UPTREND / +1 DOWNTREND** (counterintuitive; CORROBORATED at import by
   multiple independent sources quoting the Pine reference); CMO
   (−100..+100); RCI (Spearman-style rank correlation, −100..+100).
3. Crossover discipline: `ta.crossover(a, b)` fires on the bar of crossing;
   in realtime that bar is unconfirmed → repaint risk (see
   repainting-and-lookahead): gate with `barstate.isconfirmed` or `[1]`;
   MA crossovers are laggy by construction — tune lengths per asset (see
   optimization-and-calibration).
4. HMA with odd lengths: int division of len/2 changes behavior — document
   the choice.

## Workflow

1. Select the MA/directional tool per need from the verified table (rule 1–2).
2. For KAMA, use the manual implementation (rule 1) — never `ta.kama`.
3. Read supertrend via the verified sign convention (rule 2); add an explicit
   comment in planned code to prevent sign flips.
4. Gate crossovers for repaint (rule 3); document lag expectations.

## Constraints

- No `ta.kama` (does not exist); no real-time pivot/MA-cross signals without
  confirmation gating.
- Length conventions must be revalidated per asset class.

## Assumptions

- Signatures/formulas verified against the v6 reference by the source; the
  alma 5-param signature and supertrend sign independently corroborated at
  import.

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| ta.kama call | compile error | rule 1: manual implementation |
| Supertrend sign flipped | inverted signals | rule 2: −1 up / +1 down |
| HMA odd-length surprise | behavior change | rule 4: document int division |
| Live crossover repaint | history/realtime mismatch | rule 3: isconfirmed/[1] |

## Dependencies

Optional: technical-analysis-core (pillar context),
repainting-and-lookahead (confirmation gating), regime-detection (ADX/supertrend
consumers), optimization-and-calibration (length tuning). Load only on their
own triggers.

## Examples

- "Which MA reacts fastest with controlled smoothness?" → rule 1 HMA/ALMA
  tradeoffs.
- "Why is my supertrend strategy inverted?" → rule 2 sign convention.
- Persian: «KAMA در پایین اسکریپت هست؟» → rule 1: no — manual reference.

## Verification Criteria

- Only verified functions called; KAMA implemented manually where needed.
- Supertrend direction interpreted with the −1/+1 convention (comment present).
- Crossover logic carries confirmation gating.
- ALMA calls use the 4-arg form or explicitly justify the floor param.

## Ambiguities

- None from the source. (The alma floor param was corroborated, not merely
  asserted — see Import Notes.)

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-004` import from `skills/incoming/35-trend-indicators.md`.
- Import-time verification: (a) supertrend direction sign (−1 up / +1 down)
  corroborated by multiple independent sources including one quoting the Pine
  v5/v6 reference and TradingView script descriptions using the same
  convention; (b) `ta.alma` 5-parameter signature (…, sigma, floor) — floor
  optional bool default false — corroborated via a detailed v6-labeled
  reference listing; 4-arg calls remain valid.
- Layer decision: RESEARCH (indicator knowledge/design domain, consumed at
  Formalization/Planning; implementations remain implementation-stage work) —
  consistent with technical-analysis-core's classification. Resolves the
  batch-002/003 pending pointer from numerical-methods.
- Structural reorganization only; no semantic changes.

## Source Reference

- Original filename: `35-trend-indicators.md`
- Original source path: `skills/incoming/35-trend-indicators.md`
- Import batch: `batch-004`
- Normalization status: normalized
- Validation status: passed (two signature-level claims corroborated)
- Import date: 2026-09 (batch-004)
