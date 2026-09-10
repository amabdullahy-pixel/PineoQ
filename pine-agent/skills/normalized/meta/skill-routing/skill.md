# Skill: skill-routing

## Metadata

```yaml
id: skill-routing
name: Skill Routing
version: 1.0.0
path: skills/normalized/meta/skill-routing/skill.md
layer: META
domains: [agent-operations, routing]
triggers:
  english:
    - task classification routing
    - minimum skill set selection
    - classification skill map
    - conflict hierarchy skills
    - anti-patterns routing
    - verification routing
  persian:
    - مسیریابی مهارت‌ها
    - حداقل مهارت‌های لازم
    - طبقه‌بندی درخواست
dependencies:
  mandatory: []
  optional: [pine-version-intelligence, documentation-verification,
    requirements-engineering, natural-language-to-math,
    code-review-and-refactoring, research-methodology,
    falsification-and-counterexamples, walk-forward-and-validation,
    regime-detection, adaptive-systems, pine-debugging-and-testing,
    project-knowledge-management, pine-project-documentation,
    context-compression, repainting-and-lookahead,
    pine-performance-engineering]
status: normalized
priority: 1
```

## Purpose

The management brain: classify the request → select MINIMUM required skills
→ load → reason → implement → verify. Used at the start of EVERY request,
before any code or answer.

## Triggers

Select for: start of every request; deciding which skills to load;
over-routing/under-routing audits; conflict resolution between skills.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| User request | natural language | user | yes |
| Registry state | skills/registry.yaml | Import Mode | yes |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Task classification | routing output | all stages |
| Minimum skill set | selection | context loading |
| Verification routing | stage plan | verification stages |

## Rules

1. Routing pipeline: USER REQUEST → TASK CLASSIFICATION {question | review
   | bug | research | build | optimize | refactor | doc} → REQUIRED SKILLS
   (minimum set from the registry) → LOAD MINIMUM SKILLS → REASON →
   IMPLEMENT → VERIFY (routed per task class).
2. Classification → skill map (minimum sets; registry ids per the 77-skill
   library): question about behavior/feature → core {06, 75} + topic domain
   (e.g., 12/13); build indicator/strategy → core {01, 06} + topic skills
   (34–47…) + engineering {68, 72, 09}; debug an error → core {06, 70} +
   domain of the symptom + {69 if perf/limits}; review/audit code → core
   {06, 71} + {12 repaint audit} + {69, 76}; research an idea → core {06} +
   {62–67} + {51–54}; optimize/tune → core {06} + {47, 48} + {51–54, 69};
   refactor → {71} + {12} + {68, 70, 74}; document → {73, 77} + {74}.
3. Selection rules: MINIMUM set — loading everything dilutes precision;
   expand later on demand. Skill 06 (pine-version-intelligence) is in EVERY
   set that touches code/APIs. Domain layers activate by subject: price
   data → 12–15; math → 16–20; stats → 21–28; risk → 29–33; TA → 34–39;
   structure → 40–43; quant → 44–50; backtest → 51–54; macro → 55–58;
   behavior → 59–61; research → 62–67. Conflicts resolve by hierarchy:
   research skills (62–67) govern quant claims; 06 governs API facts; 62/66
   govern validity claims. If the request implies a skill that doesn't
   exist → say so + propose creating one (manifest decision row —
   project-knowledge-management).
4. Verification routing: code → compile + golden-set
   (pine-debugging-and-testing) · claims → ledger citation
   (project-knowledge-management) · facts → docs pipeline
   (documentation-verification) · research → battery
   (falsification-and-counterexamples) + OOS (walk-forward-and-validation).
5. Anti-patterns: routing by keyword matching only ("RSI" → blindly loading
   momentum-indicators without checking whether the task is about RSI
   logic, its repainting, or its API); loading zero skills and answering
   from memory (violates pine-version-intelligence); over-routing trivial
   questions (a syntax question needs pine-language-core, not the full TA
   domain).

## Workflow

1. Classify the task into exactly one class (rule 1).
2. Assemble the minimum set via the map (rule 2) + selection rules
   (rule 3).
3. Resolve conflicts by hierarchy (rule 3); note missing skills explicitly
   (rule 3).
4. Route verification per the class (rule 4); avoid the anti-patterns
   (rule 5).

## Constraints

- Never load everything (dilutes precision).
- Never answer code/API questions from memory (violates
  pine-version-intelligence / documentation-verification).
- Never over-route trivial questions.

## Assumptions

- Created as the routing brain for the 77-skill library; the map extends
  as the library grows (Decisions Log — source-declared). This skill
  documents the AGENT-side routing method; executable Router logic remains
  out of scope for Import Mode (architecture stage governs
  meta/skill_router.md).

- Scope note: the classification map uses library-internal numbering (06, 70, 71, 72…)
  which maps deterministically to registry skill IDs (the file numbering
  IS the id source).

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| Keyword-only routing | wrong granularity | rule 5: classify first |
| Memory answers | no skill loaded | rule 3: 06 mandatory |
| Over-routing | trivial question, full domain | rule 3: minimum set |
| Missing skill silently | implied skill absent | rule 3: propose creation |

## Dependencies

Optional: pine-version-intelligence (every code/API set),
documentation-verification (facts), requirements-engineering +
natural-language-to-math (build class), code-review-and-refactoring
(review class), research block + backtest block (research/optimize
classes), regime-detection + adaptive-systems (optimize class),
pine-debugging-and-testing (debug class), project-knowledge-management +
pine-project-documentation + context-compression (document class),
repainting-and-lookahead + pine-performance-engineering (audit routing).
Load only on their own triggers.

## Examples

- "Why does my signal fire twice?" → class: debug → {06, 70} + repaint
  domain.
- "Review before publishing" → class: review → {06, 71, 12, 69, 76}.
- Persian: «برای این درخواست چه چیزهایی لازمه؟» → rule 2 map + rule 3
  minimum set.

## Verification Criteria

- Exactly one task class assigned per request.
- Minimum set assembled via map + selection rules (never everything).
- Conflicts resolved by the documented hierarchy.
- Verification routed per class; anti-patterns avoided.

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-008` import from `skills/incoming/75-skill-routing.md`.
- Layer META (function = agent-request management — mirrors
  meta/skill_router.md). The skill documents the routing METHOD as
  knowledge; it does NOT implement the Router (architecture preserved; no
  executable agent logic created in Import Mode). The classification map's
  numeric ids map deterministically to registry ids (file numbering = id
  source). Structural reorganization only; no semantic changes.

## Source Reference

- Original filename: `75-skill-routing.md`
- Original source path: `skills/incoming/75-skill-routing.md`
- Import batch: `batch-008`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-008)
