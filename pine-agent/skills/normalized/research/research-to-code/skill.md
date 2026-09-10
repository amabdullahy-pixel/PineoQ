# Skill: research-to-code

## Metadata

```yaml
id: research-to-code
name: Research to Code
version: 1.0.0
path: skills/normalized/research/research-to-code/skill.md
layer: RESEARCH
domains: [research-methods, implementation-planning]
triggers:
  english:
    - research to production pipeline
    - stage gates artifact
    - signal path diff
    - pine compatible model
    - warm-up state inventory
    - productionization divergence
  persian:
    - از پژوهش تا کد
    - دروازه‌های مرحله‌ای
    - تبدیل مدل به پیاده‌سازی
dependencies:
  mandatory: []
  optional: [hypothesis-and-formula-engineering, pine-code-architecture,
    pine-performance-engineering, repainting-and-lookahead,
    mtf-engineering, data-integrity, backtesting-science,
    drawing-and-visualization, performance-metrics]
status: normalized
priority: 1
```

## Purpose

The full bridge: Research → Concept → Formula → Algorithm → Pine-compatible
Model → Implementation → Validation — with stage gates so ideas do not die
silently between research and production.

## Triggers

Select for: moving any validated research idea into a production Pine
artifact; "it worked in research but not in production" divergences;
implementation planning for a validated model.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Validated research artifact | hypothesis sheet | hypothesis-and-formula-engineering | yes |
| Preregistered parameters | manifest record | research-methodology | yes |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Stage-gate artifacts chain | planning records | Implementation Planning |
| Production implementation contract | handoff | implementation/contract_schema |
| Signal-path diff requirement | verification gate | Post-Verification |

## Rules

1. Stage gates (each has an artifact + a test): 1 RESEARCH — artifact:
   hypothesis sheet (hypothesis-and-formula-engineering); gate: mechanism
   named. 2 CONCEPT — artifact: 5-line spec (what/when/where/why/risk).
   3 FORMULA — artifact: math spec + ≥2 alternative formulations
   (hypothesis-and-formula-engineering). 4 ALGORITHM — artifact: pseudocode
   incl. state, warm-up, budget analysis. 5 PINE MODEL — artifact:
   research-version script (hardcoded params, prints). 6 IMPLEMENTATION —
   artifact: production script (inputs, architecture —
   pine-code-architecture). 7 VALIDATION — artifact: research-methodology
   loop results + repaint audit (repainting-and-lookahead).
2. Algorithm stage (before any Pine): state inventory — what persists
   across bars? (var/varip choice — tradingview-execution-model);
   complexity — per-bar cost O(?), loops bounded, arrays trimmed
   (pine-performance-engineering); warm-up — first valid bar index per
   series, gate logic on it (time-series-analysis); edge-case list — first
   bars, flat series, empty arrays, session edges (numerical-methods).
3. Pine-compatible model (the translation step — where ideas die silently):
   replace math ops with exact Pine semantics (float precision —
   numerical-methods); conditional ta.* calls restructured to global
   computation (pine-language-core); HTF terms through the non-repaint
   pattern (repainting-and-lookahead / mtf-engineering) or marked as
   research-only-repainting; window functions mapped to verified ta.*
   (statistics-core) or manual loops with caps.
4. Implementation requirements: inputs for every preregistered parameter,
   defaults = preregistered values; NO logic changes vs the validated
   model — diff the signal path line by line; dashboard/labels optional,
   performance budget respected (drawing-and-visualization /
   pine-performance-engineering).
5. Validation gate (production = research, provably): signal-path diff —
   zero unintended changes vs model; repaint checklist clean
   (repainting-and-lookahead); costs/caps/limits configured
   (backtesting-science); same pinned period reproduces model metrics
   within tolerance.

## Workflow

1. Confirm the research artifact exists (rule 1 gate 1) — else return to
   hypothesis-and-formula-engineering.
2. Walk the gates in order, producing each artifact (rule 1).
3. Execute the translation step explicitly (rule 3); record every semantic
   substitution.
4. Run the validation gate (rule 5) before declaring production.

## Constraints

- No rewriting the signal during "productionization" (silent divergence).
- No skipping the algorithm stage (architecture bugs + timeouts —
  pine-performance-engineering).
- No shipping research code with hardcoded params as final.
- No visual-only validation (metrics — performance-metrics).

## Assumptions

- Stage gates formalized by the source; cross-linked checks consistent
  with verified inventories.

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| Production ≠ research signals | no diff | rule 4/5: line-by-line diff |
| Timeout after skipping algorithm stage | budget analysis absent | rule 2: gates mandatory |
| Hardcoded research script shipped | no inputs | rule 4: promote params |
| Visual-only validation | no metric reproduction | rule 5: pinned metrics |

## Dependencies

Optional: hypothesis-and-formula-engineering (research artifacts),
pine-code-architecture (production structure),
pine-performance-engineering (budgets), repainting-and-lookahead /
mtf-engineering (HTF/non-repaint), data-integrity (na handling),
backtesting-science (costs), drawing-and-visualization (viz budget),
performance-metrics (validation metrics). Load only on their own triggers.

## Examples

- "Turn my tested idea into a clean indicator" → rule 1 gates → rule 3.
- "Research and live signals differ" → rule 5 signal-path diff.
- Persian: «ایده‌ام تو پین جواب نداد» → rules 3–5 translation audit.

## Verification Criteria

- All seven stage artifacts exist and are ordered.
- Translation substitutions documented.
- Signal-path diff clean; pinned-period metric reproduction within
  tolerance.
- Repaint audit clean before production declaration.

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-007` import from `skills/incoming/65-research-to-code.md`.
- Layer RESEARCH (pipeline governance methodology); it hands off to the
  IMPLEMENTATION-layer skills rather than duplicating them. Source's
  illustrative code-fence (`var float rollingSum`) appears in skill 69's
  source, not here — this skill's gates preserved as prose. Structural
  reorganization only; no semantic changes.

## Source Reference

- Original filename: `65-research-to-code.md`
- Original source path: `skills/incoming/65-research-to-code.md`
- Import batch: `batch-007`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-007)
