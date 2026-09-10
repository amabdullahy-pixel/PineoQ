# Skill: liquidity-and-price-structure

## Metadata

```yaml
id: liquidity-and-price-structure
name: Liquidity & Price Structure
version: 1.0.0
path: skills/normalized/research/liquidity-and-price-structure/skill.md
layer: RESEARCH
domains: [market-structure, liquidity]
triggers:
  english:
    - liquidity pools sweeps
    - stop run
    - fair value gap FVG
    - order block OB
    - displacement
    - consequent encroachment
    - inverse FVG
    - equal highs lows
  persian:
    - نقدینگی و استاپ‌هانت
    - گپ ارزش منصفانه
    - بلوک سفارش
    - جابجایی قیمتی
dependencies:
  mandatory: []
  optional: [market-structure, price-action-patterns, signal-fusion, falsification-and-counterexamples]
status: normalized
priority: 1
```

## Purpose

Liquidity pools, sweeps/stop runs, FVG, order blocks, and imbalances —
definitions plus Pine detection patterns. SMC concepts lack a single canonical
specification: thresholds are parameters to falsify (source self-declares
confidence=medium intentionally).

## Triggers

Select for: liquidity-aware entries; stop placement near pools; SMC-style
systems; FVG/OB detection design; sweep/stop-run logic; imbalance zones.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Liquidity-structure requirement | description | formalization contract | yes |
| School variants chosen (OB definition, tolerances) | parameters | user/formalization | yes |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Zone-engine design (UDT arrays) | implementation pattern | Implementation |
| Displacement/mitigation filters | code patterns | Implementation |
| School-variant declarations | documentation requirement | Pre-Verification |

## Rules

1. Liquidity pools & sweeps: buy-side liquidity (BSL) = stop clusters ABOVE
   highs; sell-side (SSL) below lows; equal highs/lows (EQH/EQL) = flat
   levels = dense liquidity magnets. Sweep (stop run) = wick through level +
   close back inside — detect with `[1]`-excluded extremes
   (`low < ta.lowest(low,20)[1] and close > ta.lowest(low,20)[1]`, mirrored
   for BSL); EQH detection: |high[i] − high[j]| ≤ tol for two pivots (tol in
   ATR units, e.g., 0.1–0.25·ATR) with min bar separation.
2. Fair Value Gap (3-candle standard): bullish FVG `low[0] > high[2]` → gap
   zone = [high[2], low[0]] (middle candle = displacement body); bearish
   mirrored `high[0] < low[2]`; Consequent Encroachment (CE) = 50% of the gap;
   inverse FVG — a filled/broken FVG flips role (broken bull FVG →
   resistance); mitigation = zone "used" when price trades fully through it —
   track with a UDT array {top, bottom, dir, state} (see pine-data-structures)
   and mark/delete mitigated zones.
3. Order blocks & displacement: bullish OB = last DOWN candle before an up
   displacement that breaks structure; zone = that candle's open–low (or
   high–low variants per school — PARAMETERIZE); displacement filter example —
   body > k·avgBody (e.g., 1.5×) plus close-position-of-range > 0.6 with
   tr/mintick guards; breaker block = failed OB broken through → opposite
   role on retest.
4. Engineering notes: store zones as UDT arrays; cap counts (see
   drawing-and-visualization limits); merge overlapping zones by tolerance;
   render with box.new; evaluate mitigations on CLOSE basis; sweep+FVG+OB
   confluence scored via signal-fusion (not additive-blind).
5. Confirmation: live-bar zone detection without confirmation repaints —
   gate on confirmed bars (see repainting-and-lookahead).

## Workflow

1. Declare the school variants (OB zone definition, tolerances) BEFORE coding
   (rules 2–3).
2. Implement zone storage/merge/mitigation per rule 2/4 with bounded arrays.
3. Gate all detection on confirmed bars (rule 5).
4. Feed confluence scoring to signal-fusion (rule 4).

## Constraints

- No hard-coded school-specific variants without declaration.
- Zone arrays bounded (unbounded growth = memory/timeouts).
- Every gap is not an FVG — displacement context required.

## Assumptions

- SMC definitions vary by school (community-standard provenance, not official
  docs); all thresholds are tunable defaults to falsify per symbol (see
  falsification-and-counterexamples).

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| Undeclared OB variant | ambiguous zones | rule 3: declare school first |
| Unbounded zone arrays | slowdown/limit | rule 4: cap + mitigate |
| Every gap treated as FVG | false zones | rule 2: displacement context |
| Live-bar detection repaints | zones flicker | rule 5: confirmation gate |

## Dependencies

Optional: market-structure (BOS/CHoCH context), price-action-patterns
(pivot/zone storage), signal-fusion (confluence scoring),
falsification-and-counterexamples (threshold falsification). Load only on
their own triggers.

## Examples

- "Detect SSL sweeps below equal lows" → rule 1 sweep pattern.
- "Track FVGs until mitigated" → rule 2 UDT zone state.
- Persian: «استاپ‌هانت را چطور تشخیص بدهم؟» → rule 1 sweep definition.

## Verification Criteria

- School variants and tolerances documented as parameters.
- Zone arrays bounded with mitigation state machine.
- All zone/sweep detection confirmed-bar-gated.
- Confluence uses distinct-family scoring (signal-fusion), not additive-blind.

## Ambiguities

- SMC definitions lack a canonical specification (source-declared,
  confidence=medium) — handled by mandatory parameterization + falsification
  discipline, not by picking a school silently.

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-005` import from `skills/incoming/41-liquidity-and-price-structure.md`.
- Resolves the batch-004 parked candidate with price-action-patterns
  (related_but_distinct/complementary — confirmed on import).
- Structural reorganization only; no semantic changes.

## Source Reference

- Original filename: `41-liquidity-and-price-structure.md`
- Original source path: `skills/incoming/41-liquidity-and-price-structure.md`
- Import batch: `batch-005`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-005)
