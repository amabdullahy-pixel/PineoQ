# Skill: <SKILL_ID>

> Template only. Replace every `<placeholder>` when authoring a real Skill.
> A Skill is documentation (rules + workflow + criteria), never executable code.

---

## Metadata

```yaml
id: <skill-id>                # kebab-case, unique across the registry
name: <Human-readable name>
version: 0.1.0
path: skills/normalized/<skill-id>.md
layer: <core | domain | utility>       # routing layer (see registry schema)
domains: [<domain-id>, ...]            # primary domains this Skill serves
triggers: [<keyword-or-phrase>, ...]   # exact-match Router triggers
dependencies:                          # other Skill ids
  mandatory: [<skill-id>, ...]
  optional: [<skill-id>, ...]
status: draft                          # draft | active | review-needed | archived | rejected
priority: <1-10>                       # 1 = highest; used for tie-breaks and compression
```

## Purpose

<One paragraph: the specific capability this Skill provides and when it is the
right tool. What would be hard or wrong without it?>

## Triggers

<The concrete signals (words, request shapes, artifact types) that should cause
the Router to select this Skill. Keep triggers precise — false matches waste
context; missing matches starve the pipeline.>

## Required Inputs

| Input | Type | Source | Required |
|---|---|---|---|
| <input-1> | <contract field / user answer / artifact> | <stage or file> | <yes/no> |

## Outputs

| Output | Type | Consumer |
|---|---|---|
| <output-1> | <section fill / contract field / decision> | <next stage> |

## Rules

<Binding rules this Skill adds for its scope. Must not contradict
AGENT_RULES.md; conflicts resolve in favor of AGENT_RULES.md.>

## Workflow

<Numbered steps the agent follows when this Skill is active. Reference the
pipeline stage(s) where each step occurs.>

## Constraints

<Hard limits: platform budgets, v6-only constructs, forbidden patterns,
scope boundaries of this Skill.>

## Assumptions

<What this Skill assumes about inputs, environment, or user intent. Every
assumption must be surfaced to the assumptions tracking of the active stage.>

## Failure Cases

| Failure | Detection | Response |
|---|---|---|
| <failure-1> | <how detected> | <blocker / user query / fallback> |

## Dependencies

<How mandatory dependencies are used, and when optional ones would be pulled
in (they must match triggers independently per routing policy).>

## Examples

<2-3 short worked examples of requests this Skill handles and how its output
feeds the next stage. Skeletons, not full case studies.>

## Verification Criteria

<Checkable criteria that determine whether this Skill's contribution is
correct. Each criterion should be verifiable at Pre- or Post-Verification.>
