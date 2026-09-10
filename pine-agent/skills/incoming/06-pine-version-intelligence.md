---
name: pine-version-intelligence
category: Pine Script Core
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/pine-script-docs/release-notes/
  - https://www.tradingview.com/pine-script-docs/migration-guides/
  - https://www.tradingview.com/blog/en/
---

# Pine Version Intelligence

## Purpose
MANDATORY verification pipeline so the agent NEVER guesses Pine features/versions
from memory. Memory = stale; docs = truth.

## When to Use
- ALWAYS before writing Pine code, suggesting APIs, or claiming "X is supported".
- Whenever a script fails on a supposedly valid API.
- On any TradingView update rumor or new-version discussion.

## The Pipeline (execute in order, every time)

```
Current Pine Version
        ↓  (check //@version= target of the project; today: v6)
Official Documentation
        ↓  (tradingview.com/pine-script-docs/ — language/ + concepts/ + reference/)
Release Notes
        ↓  (monthly notes: additions, changes, deprecations)
Deprecated Features
        ↓  (is the planned API deprecated or changed?)
Current API
        ↓  (confirm exact signature, qualifiers, limits in Reference manual)
Implementation
```

## Rules
1. NEVER assert an API exists, exists with a signature, or was removed — unless
   confirmed against official docs in this pipeline.
2. If docs unreachable → say so explicitly and mark code with
   `// UNVERIFIED-API: confirm in docs` instead of guessing.
3. Version must match the script's `//@version=` — v5 answers may be WRONG for v6
   (booleans, casting, requests, loops all changed).
4. Deprecations apply per-version. A function valid in v5 may be removed/changed in v6.
5. Future versions: treat v7/v8 as UNKNOWN until officially documented. Plan migrations
   only from official migration guides when they appear.

## Official Sources (canonical)
- Reference manual: tradingview.com/pine-script-reference-v6/
- User manual: tradingview.com/pine-script-docs/
- Release notes: tradingview.com/pine-script-docs/release-notes/
- Migration guides: tradingview.com/pine-script-docs/migration-guides/
- Blog announcements: tradingview.com/blog/

## Failure Handling
- Compile error "could not find function" → run pipeline; likely renamed/deprecated.
- Behavior differs from memory → assume v6 semantics; check release notes for the
  specific function's change log.

## Corrections & Updates
- [2026-09] Verified: v6 current (released 2024-12-10); v7 not announced; recent
  additions: request.footprint (2026-01), multiline strings (2026-04), once (2026-08).
