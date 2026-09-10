---
name: fibonacci-and-harmonic
category: Market Structure & Geometry
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/pine-script-reference/v6/
  - https://chartschool.stockcharts.com/table-of-contents/trading-strategies-and-models/trading-strategies/harmonic-patterns
---

# Fibonacci & Harmonic

## Purpose
Fib retracements/extensions/projections, confluence, harmonic XABCD patterns —
manual Pine implementations (NO built-ins exist).

## When to Use
- Level-based targets/entries, pattern completion zones, confluence scoring.

## Core Knowledge

### No Built-ins (verified)
- No ta.* functions for Fibonacci, harmonic, Elliott, or Gann — chart tools
  only. All programmatic implementations are manual (pivots + arrays +
  line/label drawing).

### Fibonacci Levels
- Constants: `math.phi` (1.618…), `math.rphi` (0.618…).
- From swing span (bull swing: low→high, span = high−low):
  - Retracement levels: `high − span·R` for R ∈ {0.236, 0.382, 0.5, 0.618, 0.786}.
  - Extensions (from low, beyond high): `low + span·E` for E ∈ {1.272, 1.618, 2.0, 2.618}.
  - Projections (measured move from next swing): anchor + priorLeg·ratio.
- Swing anchors from `ta.pivothigh/pivotlow` stored in UDT {price, barIndex};
  CURRENT active swing = last confirmed pivot pair (lag = rightBars, skill 12).

### Confluence (zone stacking)
- Confluence zone = multiple independent level families within tolerance
  (e.g., 0.3·ATR): fib 0.618 + prior S/R + VWAP band + round number.
- Score = count of DISTINCT families (cap weights, skill 46); overlapping fib
  levels of the SAME swing ≠ confluence.

### Harmonic Patterns (accepted ratio table)
| Pattern | B (of XA) | C (of AB) | D |
|---|---|---|---|
| Gartley | 0.618 | 0.386–0.886 | 0.786 XA |
| Bat | 0.382–0.50 (<0.618) | 0.382–0.886 | 0.886 XA |
| Butterfly | 0.786 | 0.382–0.886 | 1.272–1.618 XA |
| Crab | 0.382–0.618 | 0.386–0.886 | 1.618 XA |

- Detection sketch: pivots → X,A,B,C,D candidates → ratio tests with tolerance
  (±5–10% per school) → D = potential reversal zone (PRZ); trade on reaction
  AT the zone, never on the projection alone.
- Ratios from alt legs: AB=CD symmetry check; BC extension for D projection
  (1.13–3.618 of BC) per school — declare your table in the skill manifest.

## Common Mistakes
- Auto-retracing from UNconfirmed swings (repaints the whole level map).
- Harmonic detection with zero tolerance (real data never matches exactly).
- Counting same-family levels as confluence.
- Drawing infinite label/line sets (limits, skill 10).

## Corrections & Updates
- [2026-09] Created; ratio table from StockCharts ChartSchool; no-built-ins
  verified against v6 reference.
