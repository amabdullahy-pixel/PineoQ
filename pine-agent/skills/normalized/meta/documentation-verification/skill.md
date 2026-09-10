# Skill: documentation-verification

## Metadata

```yaml
id: documentation-verification
name: Documentation Verification
version: 1.0.0
path: skills/normalized/meta/documentation-verification/skill.md
layer: META
domains: [knowledge-management, verification]
triggers:
  english:
    - verify API exists signature
    - documentation tiers T1 T2 T3 T4
    - deprecated API detection
    - release notes check
    - plan gated feature claim
    - anti hallucination gate
  persian:
    - راستی‌آزمایی مستندات
    - بررسی وجود تابع
    - تشخیص API منسوخ
dependencies:
  mandatory: []
  optional: [pine-version-intelligence, pine-language-core, pine-type-system,
    mtf-engineering, multi-symbol-engineering, backtesting-science,
    drawing-and-visualization, pine-performance-engineering,
    project-knowledge-management]
status: normalized
priority: 1
```

## Purpose

Official documentation, API verification, version verification, deprecated
API detection, TradingView limitation verification — the anti-hallucination
gate for every fact claim.

## Triggers

Select for: before ANY claim about an API's existence/signature/behavior;
before using any function not used 100+ times by the agent this month; on
every session start for version/policy changes.

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| Claim to verify | statement | any stage | yes |
| Reference/release-notes access | source | official TradingView docs | yes |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| Tiered verification verdict (T1–T4) | claim language | all stages |
| Deprecated/removed-API findings | constraint records | project-knowledge-management |
| Verification-date + URL record | provenance | project-knowledge-management |

## Rules

1. Verification tiers (claim strength): T1 — verified in the v6 reference
   THIS session → "exists: signature …"; T2 — verified in the
   user-manual/docs page → "documented behavior: …"; T3 — verified via
   release notes → "added in <month>, plan-gated?"; T4 — memory/community
   only → "UNVERIFIED — must check". T1/T2 claims cite the URL. T4 claims
   NEVER shape architecture; they only mark TODO-verify.
2. The reference manual (primary source):
   tradingview.com/pine-script-reference/v6/ — per-function page carries:
   signature, parameter types/qualifiers, returns, remarks, examples,
   version note. Signature check = parameter ORDER + types + qualifiers
   (pine-type-system) — same name with a different overload counts as a
   different fact.
3. Version verification: script version (`//@version=`) vs feature
   availability per version; migration guides (v5→v6) for behavior diffs
   (booleans, casting, requests); release notes monthly — additions,
   deprecations, plan gating (footprint 2026-01, `once` 2026-08 — verified
   examples consistent with pine-v6, batch-001).
4. Deprecated/removed-API detection: search release notes + migration guide
   for the identifier; patterns seen — `request.quandl` (removed),
   `transp`/`when` params (removed), negative indices/`once` (added);
   in-code detection — reference shows "(deprecated)" or behavior warnings
   → flag in manifest Dependencies (project-knowledge-management) with a
   migration path.
5. Limitation verification: the limitations page is truth for execution
   time, loops, plots, drawings, requests, LTF bars, token limits
   (pine-language-core / drawing-and-visualization / mtf-engineering /
   pine-performance-engineering); plan-gated features MUST carry their
   plan tag in any skill/doc that mentions them (bar magnifier, deep
   backtesting, footprint — backtesting-science / multi-symbol-
   engineering).
6. Verification workflow (30-second version): 1 exact identifier →
   reference search; 2 found → copy signature + qualifier note → T1; 3 not
   found → release-notes search → T3 or "does not exist" (proven absence
   by search — state it); 4 ambiguous → user-manual page → T2; 5 record
   verification date + URL in the manifest when the fact is
   project-critical.

## Workflow

1. Classify the claim's current tier honestly (rule 1).
2. Run the 30-second workflow (rule 6) to promote the tier.
3. Record verification date + URL for project-critical facts (rule 6
   step 5).
4. Flag deprecated/plan-gated items with their tags (rules 4–5).

## Constraints

- No asserting from memory with confident tone (the strategy.risk.* and
  optimizer incidents in this library's own history — risk-management and
  optimization-and-calibration correction events).
- No verifying the NAME but not the parameter ORDER/types.
- No ignoring plan gating in claims.
- No citing AI-generated or community pages as official docs.

## Assumptions

- Tiers + workflow formalized by the source; two verified correction
  events logged in the library's own history (skills 30/52 — both
  independently corroborated during Import Mode batches 003/006).

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| Memory assertion | no citation | rule 1: T4 never shapes architecture |
| Name-only check | signature drift | rule 2: order/types/qualifiers |
| Plan gating omitted | feature fails on free plan | rule 5: plan tag mandatory |
| Community page cited | non-official source | constraint: official only |

## Dependencies

Optional: pine-version-intelligence (release-notes pipeline),
pine-language-core / pine-type-system (signature semantics),
mtf-engineering / multi-symbol-engineering / backtesting-science /
drawing-and-visualization / pine-performance-engineering (limitation
domains), project-knowledge-management (manifest recording). Load only on
their own triggers.

## Examples

- "Does ta.sma accept a series length?" → rule 6 workflow → T1 signature.
- "Was request.quandl removed?" → rule 4: release-notes search → proven
  absence.
- Persian: «این تابع هنوز وجود داره؟» → rule 6: reference check first.

## Verification Criteria

- Claim language matches the verified tier.
- Signatures checked for order/types/qualifiers, not just names.
- Plan-gated features carry plan tags.
- Project-critical facts recorded with date + URL.

## Ambiguities

- None from the source.

## Missing Information

- None beyond source scope.

## Import Notes

- Batch `batch-008` import from
  `skills/incoming/76-documentation-verification.md`.
- Layer META (function = fact-verification governance for the agent —
  same layer-from-function precedent as pine-version-intelligence). Its
  import resolves the registry's LAST parked duplicate-candidate pointer
  {06↔76} (open since batch-002: pine-version-intelligence = release-notes
  pipeline skill; documentation-verification = claim-tiering discipline —
  related_but_distinct, keep_separate).
- The source's correction-events reference matches Import Mode's own
  history: batch-003 (strategy.risk.* — official Strategies page +
  reference index corroborated the source's verification event) and
  batch-006 (no-built-in-optimizer — preserved with the source's own
  needs-review flag). Recorded as cross-validated provenance.
- Structural reorganization only; no semantic changes.

## Source Reference

- Original filename: `76-documentation-verification.md`
- Original source path: `skills/incoming/76-documentation-verification.md`
- Import batch: `batch-008`
- Normalization status: normalized
- Validation status: passed
- Import date: 2026-09 (batch-008)
```
