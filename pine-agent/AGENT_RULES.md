# AGENT_RULES.md — Pine Agent

Binding rules for every stage of the pipeline. **These rules outrank any single
Skill, template, or convenience.** Violations must be recorded as `blockers`.

---

## 1. Pipeline gating (hard ordering)

1. **No code generation before Formalization.** If no formalization contract
   exists for the request, the answer is *not code* — it is Formalization.
2. **No implementation if Pre-Verification has any blocker.** A non-empty
   `blockers` list in the pre-verification contract hard-stops the pipeline.
3. **No implementation if Feasibility fails** (any `blockers` entry).
   Warnings alone do not block; they must be surfaced to the user.
4. Implementation requires both an **approved formalization id** and an
   **approved feasibility id** (see `implementation/contract_schema.yaml`).
5. Stage order is fixed: Routing → Formalization → Pre-Verification →
   Feasibility → Implementation Planning → Implementation → Post-Verification.
   Stages must never be skipped, merged, or reordered.

## 2. Ambiguity and assumption tracking

6. **Ambiguities are never silently resolved.** Any unclear, underspecified, or
   conflicting part of a request is recorded in the `ambiguities` field of the
   formalization contract (id, description, options, resolution status).
7. **Assumptions are explicit.** Anything the agent must assume to proceed is
   written to the `assumptions` field before continuing. Assumptions that
   materially change behavior require user confirmation.
8. While `ambiguities` with `resolution_status: unresolved` exist that affect
   the requested behavior, `implementation_allowed` stays `false`.

## 3. Verification discipline

9. **Pre-Verification and Post-Verification are separate stages** with separate
   contracts (`verification/pre_contract_schema.yaml`,
   `verification/post_contract_schema.yaml`). Never merge their reports.
10. Pre-Verification checks *intent*: logic, mathematics, variable definitions,
    required data, assumptions, ambiguities, edge cases, feasibility status.
11. Post-Verification checks the *artifact*: syntax, types, scope, runtime
    behavior, signal equivalence, repainting, MTF, performance, edge cases,
    alerts. It runs only after Implementation.
12. **Repainting control:** every request must state a `repaint_risk`
    classification (none / low / medium / high) with the mechanism identified.
    Undeclared repaint behavior is a blocker at both verification stages.
13. **MTF validation:** any multi-timeframe construct must be assessed for
    lookahead/offset discipline (`[1]` + explicit lookahead policy), data
    availability, and TF-unit correctness before and after implementation.

## 4. Pine Script v6 compatibility

14. All output targets **Pine v6 only**. No v5/v4 syntax fallbacks.
15. `//@version=6` must be the first line of any emitted script (future rule
    application; recorded now as contract).
16. Known v6 semantics (documented for future stages): lazy evaluation of
    `and`/`or` must not hide `ta.*` calls; history offsets must be bounded
    relative values (never absolute bar indices); `request.*` budget must stay
    within TradingView limits.

## 5. Skill loading economy

17. **Minimum required Skill loading:** the Router selects only Skills whose
    triggers match the request, plus their mandatory dependencies.
18. **No loading of all Skills by default.** Full-catalog loading is forbidden.
19. Skills in `skills/archived/`, `skills/rejected/`, and
    `skills/review-needed/` are **never activated**.
20. If the registry is empty or no trigger matches, the Router fails in a
    controlled way: `status: blocked`, reason recorded, pipeline stops before
    Formalization — no fallback to "load everything".

## 6. Honesty and state

21. Validation status is always reported honestly: **ACTUALLY VERIFIED** vs
    **STATICALLY REVIEWED**. No Pine compiler exists locally; compilation
    claims require a user-reported TradingView result.
22. Every stage writes its contract artifact; failed stages record `blockers`
    with reasons instead of proceeding.
23. Architectural decisions are recorded in `CHANGELOG.md`; project state is
    tracked in Project Memory (see `meta/project_memory.md`).

## 7. Scaffold-phase exclusivity

24. During architecture stage: no Pine Script code, no Skills, registry empty,
    `implementation_allowed: false` everywhere. Import Mode and Implementation
    Mode are gated behind future manifest status changes.
