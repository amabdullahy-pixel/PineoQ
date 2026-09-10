---
name: statistical-arbitrage
category: Quantitative Trading
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.quantstart.com/articles/Cointegrated-Augmented-Dickey-Fuller-Test-for-Pairs-Trading-Evaluation-in-R/
  - https://robotwealth.com/practical-pairs-trading/
  - https://hudsonthames.org/an-introduction-to-cointegration/
---

# Statistical Arbitrage

## Purpose
Pair trading: spread construction, z-score entries, cointegration vs
correlation, half-life, correlation breakdown, relative value.

## When to Use
- Two-leg relative-value systems (A vs B, or asset vs benchmark).

## Core Knowledge

### Correlation ≠ Cointegration (the cardinal rule)
- Correlation = co-movement of RETURNS (short-term). Cointegration = long-run
  EQUILIBRIUM of PRICE levels (spread stationary). Two trending series can be
  0.99 correlated with a non-stationary spread → spurious regression,
  unbounded spread risk (skill 24 warning).

### Engle–Granger Workflow (conceptual pipeline in Pine)
1. Hedge ratio β: OLS of log(A) on log(B) over window (skill 24 manual OLS,
   or `ta.linreg` slope proxy — use LOG prices: elasticity-style β).
2. Spread: `S = ln(A) - β * ln(B)`.
3. Z-score: `z = (S - ta.sma(S, len)) / ta.stdev(S, len, false)`.
4. Entry \|z\| > 2 (long spread z<−2, short z>2); exit z→0; stop \|z\| > 3.5.
5. Formal ADF test NOT available in Pine — approximate stationarity via
   variance-ratio/Hurst (skill 27) and require the OU fit (below) to be sane.

### Half-Life (OU fit) — sizes the window
```pine
// regress ΔS on lagged S: ΔS = a + b·S[1]
float b = olsSlope(ta.change(S), S[1], len)     // manual OLS slope (skill 24)
float halfLife = b < 0 ? -math.log(2.0) / math.log(1.0 + b) : na
// use rolling window len ≈ 3–5 × halfLife for spread stats
```
- Reject the pair if half-life absurd (≤2 bars = costs eat edge; > horizon).

### Correlation Breakdown Guard
- Rolling corr of RETURNS (e.g., 20 bars): `rho = ta.correlation(rA, rB, 20)`.
- Disable/flatten when rho < rhoMin OR \|z\| > 3.5 (structural break, not
  reversion) → re-calibrate β before re-arming.

### Pine Execution Reality
- Both legs = 2 symbols via request.security (skill 15; watch the 40-request
  budget). One strategy simulates the SPREAD; per-leg sizing = qty ∝ β ratio;
  account for BOTH legs' commission/slippage in expectancy (skill 32).
- Crypto pairs: 24/7 alignment OK; cross-class pairs align sessions (skill 14).

## Common Mistakes
- Pairing on correlation alone (the #1 failure).
- Rolling β re-estimated too fast → whipsaw hedging costs.
- Trading the spread while ignoring borrow/fees of the short leg.
- No breakdown guard → position held through a structural decoupling.

## Corrections & Updates
- [2026-09] Created; workflow/half-life formulas verified against quant sources.
