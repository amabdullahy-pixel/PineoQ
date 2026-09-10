---
name: behavioral-finance
category: Behavioral Finance
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://thedecisionlab.com/biases/disposition-effect
  - https://rpc.cfainstitute.org/blogs/enterprising-investor/
  - https://www.tradingview.com/support/solutions/43000762390-funding-rate-a-guide-to-market-sentiment/
---

# Behavioral Finance

## Purpose
Loss aversion, herding, anchoring, recency/confirmation bias, disposition
effect — definitions AND measurable market-behavior consequences.

## When to Use
- Explaining price behavior; designing contrarian filters; strategy review.

## Core Knowledge

### Bias → Market Signature Map
| Bias | Definition | Market signature | Pine proxy |
|---|---|---|---|
| Loss aversion | loss pain ≈ 2× gain pleasure (Kahneman–Tversky) | stops just beyond obvious levels | liquidity sweeps (skill 41) |
| Herding | mimic the crowd | trends overshoot, bubbles | momentum percentile extremes (skill 44) |
| Anchoring | over-weight an initial number | round numbers, ATH magnet | round-level + ATH distance |
| Recency | recent = forever | late-cycle overconfidence | long-streak + rising RVOL |
| Confirmation | seek agreeing evidence | one-sided flows | funding/PCR extremes |
| Disposition effect | sell winners early, hold losers | winners clipped, losers drift | short avg win vs avg loss ratio (skill 32) |
| FOMO | fear of missing profit | late-chase volume spikes | RVOL > 2–3 on extension (skill 38) |
| Capitulation | mass panic liquidation | volume flush + huge wick + reversal | capitulation proxy (skill 60) |

### Design Implications for Systems
- Expect systematic early-exit bias in manually judged systems → mechanize
  exits (skill 33).
- Disposition-effect audit on YOUR trades: compare `avgWin vs avgLoss` and
  holding-time asymmetry from strategy.closedtrades (skill 32/28) — asymmetry
  beyond what the design intends = bias contamination.
- Contrarian filters: fade EXTREME one-sidedness only (funding/PCR/vol
  percentile extremes), never mild readings — mid-range "sentiment" is noise.

### Measurement Discipline
- Sentiment proxies are regimes/noisy — validate predictive value before use:
  IC-style test (skill 44) on the proxy vs forward returns, OOS (skill 53).

## Common Mistakes
- Treating bias narratives as mechanical rules ("everyone's fearful = buy")
  without evidence.
- Reading sentiment extremes as timing signals instead of context filters.
- Ignoring disposition-effect contamination in one's own trade data.

## Corrections & Updates
- [2026-09] Created; definitions verified vs CFA/Decision Lab; proxy table
  verified vs TradingView support article.
