---
name: regime-detection
category: Quantitative Trading
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://waylandz.com/quant-book-en/Lesson-12-Regime-Detection/
  - https://www.quantstart.com/articles/market-regime-detection-using-hidden-markov-models-in-qstrader/
  - https://www.tradingview.com/pine-script-reference/v6/
---

# Regime Detection

## Purpose
Classifying market state (trend/range/vol/expansion/momentum/mean-reversion/
transitional) to gate and parameterize strategies.

## When to Use
- Before ANY mean-reversion vs trend logic decision; risk scaling.

## Core Knowledge

### Regime Dimensions (orthogonal axes, not one label)
| Axis | Measure | Regimes |
|---|---|---|
| Direction | MA slope / structure trend (skill 40) | up / down / flat |
| Trendiness | ADX (`ta.dmi`), ER (skill 35/48) | trending (>25) / ranging (<20) |
| Volatility | ATR/BBW percentile (skill 37) | low / normal / high |
| Persistence | Hurst/variance-ratio (skill 27) | mean-rev (<0.5) / random / trend (>0.5) |

### Pine Regime Engine (composite)
```pine
[+, -, adx] = ta.dmi(14, 14)
float atrPct = ta.percentrank(ta.atr(14), 252)
bool trending = adx > 25
bool highVol  = atrPct > 80
bool lowVol   = atrPct < 20
int dir = ta.sma(close, 50) > ta.sma(close, 200) ? 1 : -1
// momentum regime: trending AND normal vol; reversion regime: !trending AND lowVol
```
- Transitional state = recent regime change within N bars
  (regime != regime[N]) → reduce size or stand down (regime flips are the
  highest-risk windows).

### Volatility Regimes
- Expansion: vol percentile rising fast (ATR percentile > 80 + ATR slope > 0).
- Contraction/squeeze: BBW/KCW percentile < 20 (skill 37) — pre-breakout posture.
- Mean-reversion strategies belong in LOW-vol ranging; trend systems in
  trending + expanding.

### Hurst / Variance Ratio (Pine approximation)
- Variance ratio: VR(k) = Var(k-bar returns) / (k·Var(1-bar returns)); VR > 1
  trending, < 1 reverting (rolling window, computed on returns).
- Re-estimate per regime window; low R² of OU fit (skill 27) = transitional.

### Discipline
- Regime labels must use CONFIRMED data (close-based, skill 12).
- One strategy per regime envelope; no strategy should "work everywhere".

## Common Mistakes
- Single-axis regime labels (trending but high-vol ≠ "trending" simply).
- No transitional-state handling (whipsaw at flips).
- ADX-only trend definitions on low-vol assets (ADX thresholds are
  asset-relative — normalize by percentile).
- Repainting regime flags from unconfirmed HTF data.

## Corrections & Updates
- [2026-09] Created; thresholds from quant practice sources — treat as
  defaults to falsify per symbol (skill 66).
