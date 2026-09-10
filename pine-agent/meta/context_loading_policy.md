# Context Loading Policy — Pine Agent

Defines what enters the agent context, in what order, and what may be reduced
under pressure. Machine-readable thresholds and priority tables live in
`config/token_policy.yaml`; this document is the narrative authority.

---

## Mandatory load order

1. **Project Manifest first** (`PROJECT_MANIFEST.yaml`) — establishes project
   status, global gates (`implementation_allowed`), and constraints before
   anything else is considered.
2. **Skill Registry second** (`skills/registry.yaml`) — metadata index only;
   Skill bodies are never bulk-loaded here.
3. **Only the selected Skills** — exactly the Skills the Router selected
   (`selected_skills`), loaded from `skills/normalized/`.
4. **Only mandatory dependencies** — transitive mandatory deps of selected
   Skills, within depth limits. Optional dependencies are loaded only if they
   independently match triggers.

## Prohibited loading

- **Do not load unrelated Skills.** Anything not in `selected_skills` ∪
  `dependency_skills` stays out of context.
- **Never activate Skills from `skills/archived/`** — retired is retired.
- **Never activate Skills from `skills/rejected/`** — failed review.
- **Never activate Skills from `skills/review-needed/`** — not yet approved;
  invisible to both Router and loader.
- `skills/incoming/` is raw staging; it becomes loadable only after a future
  normalization phase moves Skills into `skills/normalized/`.

## Prioritization under context pressure

Priorities (full table in `config/token_policy.yaml`):

| Level | Content | Under pressure |
|---|---|---|
| P0 | Core rules, active contracts, gates | **Never removed or summarized** |
| P1 | Selected Skills + mandatory dependencies | Kept while their stage is active; may be summarized after the stage completes |
| P2 | Supporting narrative docs | May be summarized |
| P3 | History, past-stage contracts, transcripts | Dropped to pointers |

Reduction order when the context is too large: drop P3 → summarize P2 →
summarize completed-stage P1 → **never** touch P0.

## Compression rules

- Remove or summarize low-priority context **only when the core Rules and
  Constraints are preserved** (P0 intact is the invariant).
- Before any compression: update Project Memory (current stage, contract ids,
  next action) so the session remains crash-safe resumable.
- Compression events are recorded — what was dropped or summarized, and when.
  Silent context loss is forbidden.
- Duplicate context is prevented at the source via the single-source authority
  map (`config/token_policy.yaml`): rules live only in `AGENT_RULES.md`,
  pipeline only in `README.md`, policies only in their config files. Skills
  reference these by pointer; never inline copies.
