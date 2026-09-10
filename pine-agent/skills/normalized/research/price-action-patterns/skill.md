# Skill: price-action-patterns

## Metadata

```yaml
id: price-action-patterns
name: Price Action Patterns
version: 1.0.0
path: skills/normalized/research/price-action-patterns/skill.md
layer: RESEARCH
domains: [technical-analysis, price-action]
triggers:
  english:
    - candlestick pattern detection
    - engulfing doji hammer
    - pivot swing points
    - breakout breakdown logic
    - support resistance zones
    - false breakout check
  persian:
    - الگوهای کندلی
    - پیوت و سوینگ
    - شکست سطوح
    - حمایت و مقاومت
dependencies:
  mandatory: []
  optional: [technical-analysis-core, repainting-and-lookahead, drawing-and-visualization, liquidity-and-price-structure]
status: normalized
priority: 2
```

## Purpose

Candles, swing points, breakouts, and support/resistance — Pine-verified
implementations with NO built-in pattern library: every pattern is manual and
must be gated on confirmed bars.

## Triggers

Select for: entry triggers from candle patterns; level-based logic; structure
confirmation; zone engines (clustered S/R); breakout/retest/false-break
designs.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Pattern/level requirement | description | formalization contract | yes |
| Pattern definition dictionary (if cited) | reference | user | conditional |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Pattern/zone implementation | knowledge applied | Implementation |
| Confirmation-lag warnings | warnings | Pre-Verification |
| Zone-engine design | implementation pattern | Implementation |

## Rules

1. Candlestick patterns (manual — NO built-ins): base measures body =
   |close−open|, range = high−low, upperWick = high − max(open, close),
   lowerWick = min(open, close) − low; reference shapes (bullEngulf, doji,
   hammer) follow from these; community pattern libraries exist (import per
   pine-functions-libraries) but verify pattern definitions match YOUR
   trading definition before use (see documentation-verification).
2. Swing points (pivots): `ta.pivothigh(l, r)`/`ta.pivotlow(l, r)` return the
   pivot PRICE r bars AFTER confirmation, else na; confirmation lag is
   structural (see repainting-and-lookahead); store confirmed swings in
   `var array<float>` + `var array<int>` (bar indices) — the basis for
   structure logic (see market-structure).
3. Breakouts & breakdowns: `breakUp = close > ta.highest(high, len)[1]` — [1]
   excludes the developing bar (prevents "self-breaking"); quality filters —
   close (not just high) beyond level, RVOL > threshold (see volume-analysis),
   retest logic (price returns to level within N bars without closing back
   inside); false-breakout check — close back inside level → fail (stop-run
   awareness, see liquidity-and-price-structure).
4. Support/Resistance (manual zone engine): sources = confirmed pivots
   (clustered), session/anchor highs-lows, big-volume bars' extremes; a ZONE
   is a price band, not a line — merge pivots within tolerance (e.g., 0.5·ATR)
   into zone arrays {top, bottom, touches, lastTouchBar}; strengthen on
   touch; invalidate on close-through; render with box.new (see
   drawing-and-visualization).
5. Confirmation gating: candle patterns evaluated on bar[0] intrabar are
   unconfirmed — gate with barstate.isconfirmed (see
   tradingview-execution-model).

## Workflow

1. Fix the pattern definitions explicitly (rule 1) — no implicit dictionaries.
2. Gate all pattern reads on confirmed bars (rule 5).
3. Build swing storage from confirmed pivots (rule 2) as the structure basis.
4. Implement breakout quality filters and retest/false-break logic (rule 3).
5. Implement zones as bands with merge/touch/invalidate semantics (rule 4).

## Constraints

- No built-in candlestick patterns — all manual.
- Every pivot-based structure acknowledges R-bar confirmation lag.

## Assumptions

- No built-in pattern library and pivot-lag semantics verified by the source
  against the v6 reference.

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| Intrabar pattern flip-flop | unconfirmed bar[0] reads | rule 5: isconfirmed gate |
| Self-breaking breakout | level includes current bar | rule 3: [1] exclusion |
| Every pivot becomes S/R | no clustering/strength | rule 4: zones with touches/strength |
| Definition mismatch with cited source | pattern dispute | rule 1: fix definitions first |

## Dependencies

Optional: technical-analysis-core (pillar context),
repainting-and-lookahead (confirmation/lag), drawing-and-visualization
(box rendering), liquidity-and-price-structure (stop-run depth). Load only on
their own triggers.

## Examples

- "Detect bullish engulfing reliably" → rules 1, 5.
- "Cluster my swing highs into zones" → rule 4 merge/touch semantics.
- Persian: «الگوی انگالفینگ را چطور بگیرم؟» → rules 1, 5.

## Verification Criteria

- Pattern formulas derive from explicit body/wick definitions.
- All pattern/structure reads confirmed-bar-gated.
- Breakout levels exclude the developing bar.
- Zones carry {top, bottom, touches, lastTouchBar} state with documented
  invalidate rules.

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-004` import from `skills/incoming/39-price-action-patterns.md`.
- Layer decision: RESEARCH (consistent with the TA block). Structural
  reorganization only; no semantic changes.

## Source Reference

- Original filename: `39-price-action-patterns.md`
- Original source path: `skills/incoming/39-price-action-patterns.md`
- Import batch: `batch-004`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-004)
