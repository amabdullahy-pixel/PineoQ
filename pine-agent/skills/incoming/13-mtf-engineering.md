---
name: mtf-engineering
category: Repainting & Data Integrity
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/pine-script-docs/concepts/other-timeframes-and-data/
  - https://www.tradingview.com/pine-script-docs/faq/other-data-and-timeframes/
  - https://www.tradingview.com/pine-script-docs/writing/limitations/
---

# MTF Engineering

## Purpose
Correct multi-timeframe data acquisition: HTF requests, LTF intrabars,
synchronization, and confirmation logic.

## When to Use
- Any HTF context (daily trend on 15m chart), intrabar analytics, MTF confirmation.

## Core Knowledge

### request.security() Signature & Semantics
```pine
request.security(symbol, timeframe, expression, gaps, lookahead,
     ignore_invalid_symbol, currency, calc_bars_count)
```
- timeframe: `"60"`, `"1D"`, `""`/`timeframe.period` = chart TF. Any TF
  (HTF AND LTF technically allowed — but LTF via security is WRONG, see below).
- gaps:
  - `barmerge.gaps_off` (default) — fill with last known value (historical) /
    most recent developing value (realtime).
  - `barmerge.gaps_on` — na where no new confirmed data.
- lookahead: see skill 12. Mapping without lookahead: HTF value appears on the
  LAST LTF bar of the HTF period (confirmation lag). With lookahead_on: first
  LTF bar of the period (future leak without [1]).

### Correct HTF Patterns
- Non-repainting confirmed data: `close[1] + lookahead_on` (official).
- Repainting-by-design live data: raw expression (updates intrabar, changes on reload).
- Lagged simple: `request.security(sym, tf, close[1])` with default lookahead
  (waits for HTF close, then shows — one HTF period of lag).
- Choose explicitly and DOCUMENT which pattern a script uses.

### Lower Timeframes — request.security_lower_tf()
```pine
arr = request.security_lower_tf(syminfo.tickerid, "1", close)  // array<float>
```
- Returns ARRAY of intrabar values per chart bar (oldest→newest).
- Requested TF must be STRICTLY LOWER than chart TF; otherwise errors/empty.
- Classic mistake: using `request.security()` for LTF → returns only the LAST
  intrabar, discards the rest, and repaints. Never do this.
- Intrabar budget per plan: ~100K (Basic–Premium) / 125K (Expert) / 200K
  (Ultimate) total LTF bars. Chart TFs below 1 second unsupported for data requests.
- Use cases: delta/CVD approximation, intrabar volume distribution,
  footprint-style stats.

### Timeframe Utilities
- `timeframe.in_seconds(tf)` — duration in seconds (validation, ratio guards:
  e.g., only run logic when HTF ≥ 4× chart TF).
- `timeframe.from_seconds(n)` — seconds → TF string.
- `time(timeframe, session, timezone)` — session boundary checks within MTF logic.

### Dynamic Requests (v6 default)
- `dynamic_requests = true` by default: series-string symbols/TFs, calls inside
  loops/conditionals/local scopes.
- Limits: 40 unique requests (64 Ultimate); tuple elements across all requests
  ≤ 127 (pack richer data into UDTs); duplicates (same args) don't count twice.

### Synchronization Pitfalls
- HTF confirmation lag: signal can only be as fast as the HTF bar close
  (unless intrabar HTF checks, which repaint).
- Session alignment: HTF bars anchor to exchange sessions; comparing 24/7
  crypto HTF bars with equity HTF bars misaligns timestamps.
- `calc_bars_count` limits how far back requested-context history extends.

## Common Mistakes
- request.security() on a LOWER timeframe (data loss + repaint) instead of request.security_lower_tf().
- Forgetting that `""` means chart TF in requests.
- Assuming gaps_on is "safer" — it just injects na that must be handled.
- Building MTF logic that needs tuple returns > 127 elements (limit) — use UDTs.

## Corrections & Updates
- [2026-09] Created; verified against official other-timeframes docs (v6 era).
