---
name: skill-routing
category: Agent & Software Engineering
version: 1.0.0
last_updated: 2026-09
confidence: high
sources:
  - internal architecture skill (this library)
---

# Skill Routing

## Purpose
The management brain: classify the request → select MINIMUM required skills →
load → reason → implement → verify.

## When to Use
- Start of EVERY request, before any code or answer.

## Core Knowledge

### Routing Pipeline
```
USER REQUEST
   ↓
TASK CLASSIFICATION
   ↓  {question | review | bug | research | build | optimize | refactor | doc}
REQUIRED SKILLS (minimum set)
   ↓  select from the 77-skill registry
LOAD MINIMUM SKILLS
   ↓  core + domain + engineering layers
REASON
   ↓
IMPLEMENT
   ↓
VERIFY (routed per task class)
```

### Classification → Skill Map (minimum sets)
| Task class | Core (always) | Domain | Engineering |
|---|---|---|---|
| Question about behavior/feature | 06, 75 | topic-domain (e.g., 12/13) | — |
| Build indicator/strategy | 01, 06 | topic skills (34–47…) | 68, 72, 09 |
| Debug an error | 06, 70 | domain of the symptom | 69 (if perf/limits) |
| Review/audit code | 06, 71 | 12 (repaint audit) | 69, 76 |
| Research an idea | 06 | 62–67 | 51–54 |
| Optimize/tune | 06 | 47, 48 | 51–54, 69 |
| Refactor | 71 | 12 | 68, 70, 74 |
| Document | 73, 77 | — | 74 |

### Selection Rules
1. MINIMUM set — loading everything dilutes precision; expand later on demand.
2. Skill 06 (version intelligence) is in EVERY set that touches code/APIs.
3. Domain layers activate by subject: price data → 12–15; math → 16–20;
   stats → 21–28; risk → 29–33; TA → 34–39; structure → 40–43; quant → 44–50;
   backtest → 51–54; macro → 55–58; behavior → 59–61; research → 62–67.
4. Conflicts resolve by hierarchy: research skills (62–67) govern quant
   claims; 06 governs API facts; 62/66 govern validity claims.
5. If the request implies a skill that doesn't exist → say so + propose
   creating one (manifest decision row, skill 73).

### Verification Routing
- code → compile + golden-set (70) · claims → ledger citation (73) ·
  facts → docs pipeline (76) · research → battery (66) + OOS (53).

### Anti-Patterns
- Routing by keyword matching only ("RSI" → blindly load 36 without checking
  whether the task is about RSI logic, its repainting, or its API).
- Loading zero skills and answering from memory (violates 06).
- Over-routing trivial questions (a syntax question needs 01, not the full TA
  domain).

## Corrections & Updates
- [2026-09] Created as the routing brain for this 77-skill library; extend
  the map as the library grows (Decisions Log).
