---
name: documentation-verification
category: Agent & Software Engineering
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/pine-script-docs/
  - https://www.tradingview.com/pine-script-reference/v6/
  - https://www.tradingview.com/pine-script-docs/release-notes/
---

# Documentation Verification

## Purpose
Official documentation, API verification, version verification, deprecated
API detection, TradingView limitation verification — the anti-hallucination gate.

## When to Use
- Before ANY claim about an API's existence/signature/behavior.
- Before using any function not used 100+ times by the agent this month.
- On every session start for version/policy changes.

## Core Knowledge

### Verification Tiers (claim strength)
| Tier | Requirement | Claim language allowed |
|---|---|---|
| T1 | verified in v6 reference THIS session | "exists: signature …" |
| T2 | verified in user-manual/docs page | "documented behavior: …" |
| T3 | verified via release notes | "added in <month>, plan-gated?" |
| T4 | memory/community only | "UNVERIFIED — must check" |

- T1/T2 claims cite the URL. T4 claims NEVER shape architecture; they only
  mark TODO-verify.

### The Reference Manual (primary source)
- tradingview.com/pine-script-reference/v6/ — per-function page carries:
  signature, param types/qualifiers, returns, remarks, examples, version note.
- Signature check = parameter ORDER + types + qualifiers (skill 02) — same
  name with different overload counts as different facts.

### Version Verification
- Script version (`//@version=`) vs feature availability per version.
- Migration guides (v5→v6) for behavior diffs (booleans, casting, requests).
- Release notes monthly: additions, deprecations, plan gating (footprint
  2026-01, once 2026-08 — verified examples, skill 05).

### Deprecated/Removed API Detection
- Search release notes + migration guide for the identifier.
- Patterns seen: `request.quandl` (removed), `transp`/`when` params (removed),
  negative indices/`once` (added).
- In-code detection: reference shows "(deprecated)" or behavior warnings —
  flag in manifest Dependencies (skill 73) with migration path.

### Limitation Verification
- Limitations page = truth for: execution time, loops, plots, drawings,
  requests, LTF bars, token limits (skills 01/10/13/69).
- Plan-gated features MUST carry their plan tag in any skill/doc that
  mentions them (bar magnifier, deep backtesting, footprint — skill 51/15).

### Verification Workflow (30-second version)
1. Exact identifier → reference search.
2. Found? → copy signature + qualifier note → T1.
3. Not found? → release notes search → T3 or "does not exist" (proven
   absence by search, state it).
4. Ambiguous? → user-manual page → T2.
5. Record verification date + URL in the manifest when the fact is
   project-critical.

## Common Mistakes
- Asserting from memory with confident tone (the strategy.risk.* and
  optimizer incidents in this library's own history — skills 30/52).
- Verifying the NAME but not the PARAMETER ORDER/types.
- Ignoring plan gating in claims.
- Citing AI-generated or community pages as official docs.

## Corrections & Updates
- [2026-09] Created; tiers + workflow formalized; two verified correction
  events logged (see skills 30/52 Updates).
