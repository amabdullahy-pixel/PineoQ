# Skill: market-structure

## Metadata

```yaml
id: market-structure
name: Market Structure
version: 1.0.0
path: skills/normalized/research/market-structure/skill.md
layer: RESEARCH
domains: [technical-analysis, market-structure]
triggers:
  english:
    - HH HL LH LL
    - BOS break of structure
    - CHoCH change of character
    - internal vs external structure
    - swing engine SMC
    - trend state machine
  persian:
    - ساختار بازار
    - شکست ساختار
    - تغییر کاراکتر
    - ساختار داخلی و بیرونی
dependencies:
  mandatory: []
  optional: [price-action-patterns, repainting-and-lookahead, regime-detection, liquidity-and-price-structure]
status: normalized
priority: 1
```

## Purpose

HH/HL/LH/LL, BOS, CHoCH, internal vs external structure, and a confirmed-
pivot swing engine — SMC-standard definitions with code-implementable rules
for trend state machines and SMC-style systems.

## Triggers

Select for: trend state engines; SMC-style entry models; BOS/CHoCH logic;
internal-vs-external swing classification; "is this a real break?" audits.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Structure requirement | description | formalization contract | yes |
| Pivot params (L, R) | parameters | user/formalization | yes |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Swing engine + state machine design | implementation pattern | Implementation |
| CHoCH-semantics warnings | warnings | Pre-Verification |
| Trend state as regime input | design facts | regime-detection |

## Rules

1. Definitions (community-standard, 2024–2026): uptrend = Higher Highs (HH) +
   Higher Lows (HL); downtrend = LL + LH. **BOS (Break of Structure)** =
   CONTINUATION — close beyond the prior swing in the TREND direction (bull:
   close > last swing high while bullish). **CHoCH (Change of Character)** =
   first structure break AGAINST the trend — an early reversal WARNING, not
   confirmation (bull: close < last higher low). Internal structure = minor
   swings inside major legs; external = major swings; use external for bias,
   internal for entries.
2. Swing engine (confirmed pivots): track lastSwingHigh/prevSwingHigh and
   lastSwingLow/prevSwingLow via `ta.pivothigh(high, L, R)` /
   `ta.pivotlow(low, L, R)` with var floats — pivots return price R bars
   after confirmation; classification happens on pivot confirmation (new high
   > prev high AND pullback low > prev low → HH+HL, etc.); lag = R bars
   (acknowledge — see repainting-and-lookahead).
3. BOS/CHoCH state machine: trend ∈ {1 bull, −1 bear, 0 undefined}; bull
   conditions — bosBull = close > lastSwingHigh AND trend ≥ 0; chochBull =
   close > lastSwingHigh AND trend < 0; mirrored for bear via lastSwingLow;
   transitions set trend accordingly. CLOSE-based (not wick) breaks; use
   confirmed bars (barstate.isconfirmed — see tradingview-execution-model).
4. Parameterization: SMC definitions vary between schools — parameterize L/R
   and document the choices (source verified definitions across major SMC
   references incl. LuxAlgo).

## Workflow

1. Fix pivot params and internal/external scope (rule 4).
2. Implement the swing engine from confirmed pivots (rule 2).
3. Run the close-based state machine (rule 3); label BOS vs CHoCH distinctly.
4. Feed trend state to regime/entry logic with lag acknowledged (rules 1–2).

## Constraints

- CHoCH is a warning, never a guaranteed reversal signal.
- Wick-breaks do not count as BOS (community standard: CLOSE through).
- Internal and external swings never share one state variable.

## Assumptions

- Definitions verified across major SMC sources by the source; variations
  between schools exist — parameterization and documentation are mandatory.

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| Wick-break counted as BOS | premature trend flips | rule 3: close-based only |
| CHoCH traded as reversal confirmation | early losses | rule 1: warning semantics |
| Structure repaints | unconfirmed pivots/live reads | rule 2/3: confirmed inputs |
| Mixed swing scopes | contradictory state | rule 1: separate internal/external |

## Dependencies

Optional: price-action-patterns (pivot storage patterns),
repainting-and-lookahead (confirmation lag), regime-detection (state as
regime input), liquidity-and-price-structure (S/R interaction). Load only on
their own triggers.

## Examples

- "Build an SMC trend engine" → rules 2–3 swing + state machine.
- "Warn me when the uptrend character changes" → rule 1 CHoCH as warning.
- Persian: «تفاوت BOS و CHoCH چیه؟» → rule 1 definitions.

## Verification Criteria

- BOS/CHoCH distinguished by trend context in code.
- Close-based breaks only; confirmed-bar gating present.
- Pivot lag (R bars) documented in the design.
- Internal/external swings tracked separately with documented params.

## Ambiguities

- None from the source. (Definition-school variations handled by mandatory
  parameterization per rule 4.)

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-004` import from `skills/incoming/40-market-structure.md`.
- Layer decision: RESEARCH (consistent with the TA block). Source cites SMC
  community references (LuxAlgo SMC, dailypriceaction) — recorded as
  provenance, not as official-doc authority; Pine API facts remain
  reference-verified. Structural reorganization only; no semantic changes.

## Source Reference

- Original filename: `40-market-structure.md`
- Original source path: `skills/incoming/40-market-structure.md`
- Import batch: `batch-004`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-004)
