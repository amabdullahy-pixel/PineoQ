# Skill Router — Design Specification (v2.0.0)

**Status: DESIGN — no executable Router logic exists or may be created in this phase.**
**Phase:** PHASE 3 — Router Design Mode. **Date:** 2026-09.

The Router is the first pipeline stage after the raw request. Its single
responsibility: for every user request, **select the smallest sufficient set of
Skills** (plus required dependencies) from `skills/registry.yaml`, produce a
deterministic routing decision with a full routing trace, and hand the routing
contract to Formalization. It must **never** load all Skills by default, never
modify or invent Skills, and never execute or bypass downstream stages.

Authoritative inputs (read-only):

- `skills/registry.yaml` — the populated 77-Skill Registry (Import Mode output).
- `config/routing.yaml` — routing rules in five layers (classification, matching,
  selection, dependency, context).
- `config/token_policy.yaml` + `meta/context_loading_policy.md` — context budget
  authority (mirrored, not redefined, here).
- `AGENT_RULES.md` — pipeline gating (unchanged).

Architectural separation (binding):

- **Registry** = Skill knowledge and capabilities.
- **routing.yaml** = routing and selection rules.
- **Router** = decision and routing engine (specified here; implemented later).
- **Formalization** = conversion of the routed request into a formal contract.

Skill knowledge lives ONLY in the Registry and Skill files; routing decision
logic lives ONLY here and in `config/routing.yaml`. Neither may absorb the other.

---

## 1. Design goals and success criteria

The design is successful only if:

1. Every request receives a deterministic classification (exactly one primary class).
2. The operational intent is explicit (one recorded sentence).
3. Skill selection is Registry-driven (triggers/domains/purpose/inputs/outputs/
   dependencies/constraints/verification requirements/activation status).
4. Only the minimum sufficient Skill set is loaded — never a whole domain,
   category, or the catalog.
5. Dependencies are completely resolved (recursive closure) or routing is blocked.
6. Unnecessary Skills remain unloaded.
7. Cross-domain requests are handled with the minimum cross-domain set.
8. Redundancy is controlled using the Registry's recorded overlap classifications.
9. Conflicts, ambiguity, and coverage gaps are explicit — never silently resolved.
10. Context footprint is minimized and estimated.
11. Every routing decision is explainable (routing trace).
12. No downstream stage is bypassed; only `routing_status: ready` proceeds.
13. No Skill is silently modified, merged, or invented.

## 2. Routing principles (binding)

- **Minimal sufficiency** — smallest set that fully covers the request's
  operational requirements. No loading because "related"; no whole domains; no
  whole categories; optional Skills only when their contribution is necessary.
- **Dependency closure** — every selected Skill's required dependencies resolved
  recursively until the graph is closed; a dependency loads only when required by
  an activated Skill.
- **Trigger fidelity** — registered triggers used as written (English and Persian
  equally). No broadening, no invented triggers, no capability inferred from vague
  semantic similarity.
- **Domain coverage** — multi-domain requests get the minimum cross-domain set
  that covers the complete request.
- **No speculative loading** — if a Skill is not demonstrably required, it stays
  unloaded.
- **No silent substitution** — similar Skills are never swapped on appearance;
  Registry metadata and routing rules decide the smallest sufficient combination.
- **Conflict detection** — incompatible rules/assumptions/constraints/outputs
  inside the candidate set are flagged (`conflict_detected`), never resolved
  silently by the Router.
- **Ambiguity handling** — if routing cannot be determined reliably, the result is
  `ambiguous` with the missing information listed. The Router never guesses.

## 3. Routing pipeline (14 stages)

| # | Stage | Input → Output | Failure mode |
|---|---|---|---|
| 1 | Request normalization | verbatim request → normalized text (whitespace/language tags; Persian preserved) | — |
| 2 | Intent extraction | normalized text → `operational_intent` (one sentence) | unclear intent → stage 12 `ambiguous` |
| 3 | Request classification | intent → primary `request_class` + secondary classes | undeterminable → `ambiguous` |
| 4 | Domain identification | intent + registry domains → `primary_domain`, `secondary_domains[]` | none applicable → `insufficient_coverage` |
| 5 | Matching | intent/domain vs Registry metadata → candidates with grades `match | partial_match | weak_match | no_match` | zero viable candidates → `blocked` (v0.1-compatible no-match) |
| 6 | Minimal coverage analysis | candidates → smallest set with complete required-capability coverage | gap remains → `insufficient_coverage` |
| 7 | Dependency resolution | selected set → recursive mandatory-dep closure | cycle/missing/depth → `blocked` |
| 8 | Redundancy elimination | set → set minus unnecessary overlap (per recorded overlap classifications) | — (removals recorded in trace) |
| 9 | Conflict / gap analysis | final set → conflicts[], missing_capabilities[] | conflict → `conflict_detected` |
| 10 | Context footprint estimation | final set → `estimated_context_size` (S/M/L/XL + token estimate) | XL → requires written justification in trace |
| 11 | Routing decision | all above → `routing_status` ∈ {ready, ambiguous, insufficient_coverage, blocked, conflict_detected} | — |
| 12 | Routing trace | full explainability record | — |
| 13 | Handoff | contract → Formalization (only if `ready`) | non-ready → stop before Formalization |
| 14 | Termination | Router exits; downstream stages own everything after | — |

## 4. Request classification

Exactly one **primary** class per request; secondary classes recorded when
materially present (they may add capabilities but never justify bulk loading).

Classes: `conceptual | analytical | debugging | mathematical | indicator_design |
strategy_logic | Pine_Script_implementation | MTF | performance | visualization |
verification | research | architecture | mixed`

Rules:

- `mixed` is used only when ≥2 classes are equally dominant; the dominant
  operational requirement still names the primary class inside `mixed`.
- Classification is Registry-driven: classes map to the skill-routing Skill's
  classification map and Registry domains; a class with no corresponding Registry
  coverage leads to `insufficient_coverage`, not a guess.
- Classification determinism: the same request text always yields the same class
  (no session/state dependence).

## 5. Domain selection

```yaml
primary_domain: ""       # dominant operational requirement (Registry domain id)
secondary_domains: []    # additional Registry domains that materially affect routing
```

- Domains come from Registry `domains:` values only — no invented domains.
- A domain is secondary only if it materially changes routing (adds a required
  capability or a binding constraint). Related-but-unnecessary domains are
  recorded in the trace as non-routing observations, never as `secondary_domains`.
- Cap: at most 3 secondary domains influence selection; further relevant domains
  are listed in the trace only.

## 6. Skill matching

Each Registry candidate is graded against the request using ALL of: triggers
(English + Persian), domains, purpose, required inputs, outputs, dependencies,
constraints, verification requirements, activation status.

| Grade | Meaning | Selection eligibility |
|---|---|---|
| `match` | trigger(s) + primary domain align with the operational intent; materially advances coverage | eligible |
| `partial_match` | contributes to a required capability but insufficient alone | eligible only in combination |
| `weak_match` | related only (e.g., domain match without trigger match) | **never selected alone** |
| `no_match` | irrelevant | excluded |

- Trigger fidelity: registered triggers as-is; fuzzy matching disabled; Persian
  triggers equal in force.
- Domain-only matches grade at best `weak_match`.

## 7. Minimal skill set optimization

Conceptual objective (decision procedure, not runtime code):

```text
MINIMIZE  context_cost  ≈ f(|selected|, |mandatory deps|, Σ skill size)
SUBJECT TO
  request_coverage        = complete   (all required capabilities covered)
  dependency_closure      = true
  required_capabilities   = satisfied  (incl. required verification capability)
  blockers                = none
```

Hard caps (`config/routing.yaml`): `max_selected_skills: 5`,
`max_dependency_depth: 3`, skills ≤ 60% of context share (mirrors
`config/token_policy.yaml`). Tie-breaking order: highest priority (registry
`priority`, 1 = highest) → narrowest domain match → lowest dependency count.

## 8. Dependency resolution

1. Read each selected Skill's `dependencies.mandatory`.
2. Resolve against the Registry; recursively resolve their dependencies until
   closure (depth cap 3).
3. Optional dependencies are **never** auto-resolved; one enters only if it
   independently achieves a `match` grade for this request and adds a required
   capability (then it is recorded as selected, not as a dependency).
4. Circular dependency detected → `blocked` (cycle path recorded).
5. Missing dependency (id not in Registry) → `blocked` (id named).
6. Only `status: normalized` + `activation: eligible` entries are resolvable;
   review-needed/rejected/incoming are invisible to routing.
7. Every resolved dependency recorded as `{id, required_by}` in
   `dependency_skills` (provenance preserved).

Note on the current Registry: it contains **no mandatory dependencies** (all
cross-references are optional by Import Mode design), so closure in practice adds
nothing unless future library revisions introduce mandatory edges. The rule set
still applies in full and is tested.

## 9. Redundancy analysis

- Overlap relationships come from the Import Mode record
  (`skills/import-reports/processing-index.yaml` duplicate_candidates + individual
  Import Reports) using the classifications: `exact_duplicate | partial_overlap |
  complementary | related_but_distinct | unrelated`.
- Skills are **never merged**. A candidate is removed only when its capability is
  unnecessary for complete request coverage.
- `complementary` pairs selected together are **retained** (each covers a distinct
  capability).
- `related_but_distinct` pairs: select by which capability the request actually
  needs; the other is excluded with the reason recorded.
- Every removal/retention decision is recorded in
  `routing_trace.redundancy_analysis`.

## 10. Conflict and gap analysis

Conflicts are flagged when selected Skills impose incompatible requirements, e.g.:

- opposing confirmation semantics for the same signal (close-confirmed vs
  intrabar) without a declared tolerance;
- contradictory constraint envelopes (e.g., one Skill's rules assume confirmed
  HTF data, another's pattern requires live intrabar reads);
- overlapping outputs with different contracts for the same artifact.

Resolution is NEVER performed by the Router: the result is
`routing_status: conflict_detected` with each conflict itemized; the user or a
downstream stage resolves it in a new request.

Gaps: any required capability with no `match`/`partial_match` provider appears in
`coverage.missing_capabilities`. If a required capability is missing entirely,
`routing_status: insufficient_coverage` (the request is understood; the Registry
cannot cover it — the Router proposes which Skill is absent, referencing skill
75's rule 5: say so and propose creation via a manifest decision row).

## 11. Context budget

- `estimated_context_size` = approximate tokens for: selected Skill bodies +
  mandatory dependency bodies + routing metadata.
- Estimation is metadata-only at routing time (Registry metadata + typical Skill
  size); bodies load later per `meta/context_loading_policy.md`.
- Size levels: **S** ≤ ~6k tokens (1–2 Skills, no deps) · **M** ~6k–15k ·
  **L** ~15k–30k · **XL** > ~30k (requires written justification in the trace;
  caps likely violated → reduce before handoff).

## 12. Routing status semantics

| Status | Meaning | Handoff |
|---|---|---|
| `ready` | minimum sufficient set, closure complete, no conflicts/gaps/ambiguity | **allowed** → Formalization |
| `ambiguous` | request underdetermined; missing info itemized | stop before Formalization |
| `insufficient_coverage` | request understood; Registry lacks a required capability | stop |
| `blocked` | structural failure: empty registry, zero viable candidates, dependency cycle/missing/depth | stop |
| `conflict_detected` | selected set internally incompatible | stop |

Only `ready` sets `downstream.allowed: true`.

## 13. Output contract (v2 — `contract_version: routing/2`)

```yaml
routing:
  contract_version: "routing/2"
  routing_status: ""            # ready | ambiguous | insufficient_coverage | blocked | conflict_detected
  request_class: ""             # primary class (mixed allowed; secondary classes in trace)
  primary_domain: ""
  secondary_domains: []
  operational_intent: ""        # one explicit sentence

  selected_skills:
    - id: ""
      reason: ""
      match: ""                 # match | partial_match
  dependency_skills:
    - id: ""
      required_by: ""
  excluded_skills: []           # ids not selected (audit trail; weak/no matches)

  coverage:
    required_capabilities: []
    covered_capabilities: []
    missing_capabilities: []

  conflicts: []
  ambiguity: []
  reason: ""                    # final routing reason (one paragraph)
  estimated_context_size: ""    # S|M|L|XL + token estimate

  routing_trace:
    classification: ""
    matching: ""
    minimal_set_reasoning: ""
    dependency_resolution: ""
    redundancy_analysis: ""

  downstream:
    next_stage: "FORMALIZATION"
    allowed: false              # true ONLY when routing_status == ready
```

Compatibility with v0.1 (`routing/1`): `status` is renamed `routing_status` with
the extended value set; `unresolved_triggers` is expressed via
`coverage.missing_capabilities` + `routing_trace.matching`; selected/dependency/
excluded lists and `estimated_context_size` remain. The empty-registry and
no-match controlled-failure behaviors are preserved unchanged (blocked; never
bulk-load).

## 14. Routing trace (mandatory)

Every decision records: request interpretation; primary/secondary domains;
candidates considered (id + grade); selected Skills with reasons; dependency
Skills with `required_by`; excluded Skills; redundancy decisions; conflicts;
missing coverage; final routing reason. A decision without a trace is invalid.

## 15. Safety rules (the Router must NEVER)

create / modify / rewrite / merge a Skill · activate review-needed or rejected
Skills · ignore unresolved dependencies · silently resolve conflicts · invent
triggers or capabilities · execute Pine code · implement the user's request ·
bypass Formalization, Pre-Verification, or Feasibility · authorize Implementation
while routing or downstream blockers exist.

**The Router is a selector and planner, not an implementation engine.**

## 16. Determinism requirements

- Same request text + same Registry revision ⇒ byte-identical routing contract.
- No randomness, no session state, no time dependence in the decision.
- All thresholds/caps live in `config/routing.yaml` (never hard-coded in prose).
- Tie-breaking is fully ordered (priority → narrowest domain → lowest dependency
  count → registry id lexicographic as final tiebreaker).

## 17. Appendix — worked example (design illustration, not implementation)

Request: *"Review my published strategy for repainting problems before I ship it."*

- Intent: structured pre-publication audit focused on repainting.
- Classification: primary `verification`; secondary: none material.
- Domains: primary `verification`; secondary `technical-analysis` (repaint
  semantics).
- Matching: `code-review-and-refactoring` = match (review method, three-way
  repaint verdict); `repainting-and-lookahead` = match (audit checklist);
  `pine-version-intelligence` = match (API-fact gate required by review step 1);
  `pine-performance-engineering` = weak_match (only if a perf verdict is asked
  for — excluded); `pine-debugging-and-testing` = weak_match (defect fixing, not
  review — excluded).
- Dependencies: none mandatory (Registry has no mandatory edges) → closure
  trivially complete.
- Redundancy: review (71) vs debugging (70) is `related_but_distinct` — 71
  retained, 70 excluded with reason.
- Coverage: required [structured review, repaint audit, API verification] all
  covered; missing [].
- Conflicts: none. Ambiguity: none.
- Size: 3 Skills ≈ **S**.
- Result: `routing_status: ready`; `downstream.allowed: true`;
  `next_stage: FORMALIZATION`.
