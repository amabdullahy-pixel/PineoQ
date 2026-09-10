---
name: project-knowledge-management
category: Agent & Software Engineering
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - https://www.tradingview.com/pine-script-docs/
---

# Project Knowledge Management

## Purpose
The project's single source of truth: manifest, registries
(architecture/modules/formulas/variables), known bugs, decisions,
dependencies, constraints, version history.

## When to Use
- Start of EVERY session on an existing project; after every decision/change.

## Core Knowledge

### PROJECT-MANIFEST (one file, canonical sections)
```markdown
# PROJECT-MANIFEST.md
## 1. Identity
project: <name> · pine_version: 6 · created: <date> · updated: <date>

## 2. Architecture Registry
layers & responsibilities (skill 68) · data-flow diagram (text) · entry points

## 3. Module Registry
| module/file | role | inputs | outputs | deps | status |

## 4. Formula Registry
| id | formula (exact) | version | formulations tested (≥2, skill 63) |
     | validated? OOS? (skill 62) | used-by |

## 5. Variable Dictionary
| var | type | scope | meaning | unit | persistence | where set/read |

## 6. Signal Definitions
| signal id | exact condition | semantics (close-confirmed?) | consumer |

## 7. Decisions Log (ADR-style)
| date | decision | alternatives | why | consequence |

## 8. Known Bugs / Limitations
| id | symptom | workaround | fixed-in |

## 9. Dependencies
| library/symbol/data | version/ID | plan-gated? | fallback |

## 10. Constraints
platform limits assumed · cost model · sessions · risk policy (skills 51/58/30)

## 11. Version History
| version | date | change | validated-by |

## 12. Research Ledger (trial log — skill 54)
| trial | hypothesis | verdict | data window | metrics |
```

### Operating Rules
- WRITE-BEFORE-CODE: spec updates precede implementation changes.
- Decisions are append-only (never rewrite history — record reversals as new rows).
- Registries are the agent's memory across sessions: reconstruct context from
  the manifest, not from re-reading all code (pairs skill 74).
- Every backtest claim in chat/docs must cite a ledger row (id + window + metrics).

### Consistency Checks (run on session start)
- Formula registry ↔ code diff (drift = skill 65 violation or doc lag).
- Constraints still true on current plan (skills 13/15/51 re-verify flags).
- Open bugs still open; fixed-in rows reference real versions.
- Trial ledger K counted → adjust skepticism (skill 54).

## Common Mistakes
- Manifest drift (docs lag code → trust collapses; prefer code-as-truth and
  diff-fix docs immediately).
- Decisions recorded without consequences (future-you needs the WHY + cost).
- No trial ledger → K unknowable → overfitting invisible (skill 54).
- Stale dependency IDs (symbols/plans change — skill 56 notes).

## Corrections & Updates
- [2026-09] Created; manifest schema v1 — evolve via Decisions Log.
