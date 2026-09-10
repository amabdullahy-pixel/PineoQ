# Skill: pine-version-intelligence

## Metadata

```yaml
id: pine-version-intelligence
name: Pine Version Intelligence
version: 1.0.0
path: skills/normalized/meta/pine-version-intelligence/skill.md
layer: META
domains: [documentation-verification, version-compatibility]
triggers:
  english:
    - verify pine feature
    - is this api supported
    - check release notes
    - deprecated function
    - could not find function
    - documentation check
    - api existence claim
    - pine version rumor
  persian:
    - بررسی امکانات پایین اسکریپت
    - یادداشت‌های انتشار
    - منسوخ شده
    - تابع پیدا نشد
    - تایید مستندات
dependencies:
  mandatory: []
  optional: [pine-v6, documentation-verification]
status: normalized
priority: 1
```

## Purpose

Mandatory verification pipeline so the agent NEVER guesses Pine
features/versions from memory: memory is stale, official documentation is the
truth. Governs every API-existence, signature, and deprecation claim the agent
makes — before writing Pine code, suggesting APIs, or asserting support.

## Triggers

Select ALWAYS before writing Pine code, suggesting APIs, or claiming "X is
supported"; whenever a script fails on a supposedly valid API ("could not find
function"); on any TradingView update rumor or new-version discussion.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| API/feature claim to verify | text | request or plan | yes |
| Script's target version | `//@version=` | target script | yes |
| Network access to official docs | environment | runtime | conditional |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Verified / refuted / unverified API verdict | decision | Implementation, Pre/Post-Verification |
| `// UNVERIFIED-API: confirm in docs` marker | code annotation | Post-Verification |
| Deprecation findings | warnings | Formalization, Feasibility |

## Rules

1. NEVER assert an API exists, exists with a signature, or was removed — unless
   confirmed against official docs via this pipeline.
2. If docs are unreachable, say so explicitly and mark the code with
   `// UNVERIFIED-API: confirm in docs` instead of guessing.
3. The verified version must match the script's `//@version=` — v5 answers may
   be WRONG for v6 (booleans, casting, requests, loops all changed).
4. Deprecations apply per-version; a function valid in v5 may be removed or
   changed in v6.
5. Future versions (v7/v8) are UNKNOWN until officially documented; plan
   migrations only from official migration guides when they appear.
6. Canonical sources: reference manual (tradingview.com/pine-script-reference-v6/),
   user manual (tradingview.com/pine-script-docs/), release notes, migration
   guides, blog announcements.

## Workflow

Execute in order, every time:

1. **Current Pine Version** — check the `//@version=` target of the project (today: v6).
2. **Official Documentation** — tradingview.com/pine-script-docs/ (language/ + concepts/ + reference/).
3. **Release Notes** — monthly notes: additions, changes, deprecations.
4. **Deprecated Features** — is the planned API deprecated or changed?
5. **Current API** — confirm exact signature, qualifiers, limits in the Reference manual.
6. **Implementation** — only after the above, proceed.

Failure handling: compile error "could not find function" → run the pipeline;
likely renamed/deprecated. Behavior differs from memory → assume v6 semantics;
check release notes for that function's change log.

## Constraints

- Applies to every version-sensitive claim, not only suspected ones.
- Does not decide architecture or normalize Skills — it is a verification
  service consumed by other stages (this is a META-layer skill).

## Assumptions

- Official TradingView documentation is reachable and current; when it is not,
  rule 2's explicit-unverified path applies.

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| Docs unreachable | network/tool failure | mark `// UNVERIFIED-API:`, record unverified status, never guess |
| Memory conflicts with docs | pipeline mismatch | docs win; check release notes for the change |
| Version mismatch (v5 answer for v6) | `//@version=` check | re-verify against correct version's docs |

## Dependencies

Optional: pine-v6 (version facts already curated), documentation-verification
(general documentation-integrity discipline). Not loaded unless their own
triggers match.

## Examples

- "Does `request.footprint()` exist?" → pipeline steps 2–5 → verified 2026-01,
  plan-gated.
- "My script says `could not find function ta.x`" → rule 6 failure handling;
  check deprecation first.
- Persian: «این تابع در نسخه ۶ هست؟» → full pipeline before answering.

## Verification Criteria

- Every API claim in emitted plans/code is traceable to an official source or
  explicitly marked unverified.
- No assertion of future-version (v7+) features.
- Version of verified facts matches the script's `//@version=`.

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-001` import from `skills/incoming/06-pine-version-intelligence.md`.
- Layer decision: primary layer is META (a cross-cutting verification protocol,
  not language knowledge) despite the source's "Pine Script Core" category tag —
  layer was assigned from actual function per import rules.
- The pipeline itself was exercised during this import batch (release-notes
  fetch for skills 05/08/09), which is operational evidence the process works
  as documented.

## Source Reference

- Original filename: `06-pine-version-intelligence.md`
- Original source path: `skills/incoming/06-pine-version-intelligence.md`
- Import batch: `batch-001`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-001)
