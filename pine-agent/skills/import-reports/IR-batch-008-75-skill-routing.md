# Import Report — IR-batch-008-75

```yaml
report_id: IR-batch-008-75
import_batch: batch-008
original_filename: 75-skill-routing.md
source_path: skills/incoming/75-skill-routing.md
proposed_skill_id: skill-routing
final_skill_id: skill-routing
final_status: normalized
activation_status: eligible
primary_layer: META
domains: [agent-operations, routing]
extracted_triggers:
  english: [task classification routing, minimum skill set selection,
    classification skill map, conflict hierarchy skills,
    anti-patterns routing, verification routing]
  persian: [مسیریابی مهارت‌ها, حداقل مهارت‌های لازم, طبقه‌بندی درخواست]
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
validation_results:
  unique_skill_id: pass
  clear_purpose: pass
  justified_primary_layer: pass
  justified_primary_layer_detail: function = agent-request management —
    mirrors meta/skill_router.md (layer-from-function precedent).
  valid_triggers: pass
  documented_inputs: pass
  documented_outputs: pass
  rules_documented: pass
  constraints_documented: pass
  assumptions_documented: pass
  dependencies_documented: pass
  ambiguities_recorded: pass
  missing_information_recorded: pass
  template_structure_followed: pass
  source_preserved: pass
pine_v6_findings:
  - No platform-API claims; the classification→skill map uses library
    numbering that maps deterministically to registry ids (06 = 06-pine-
    version-intelligence, 70 = pine-debugging-and-testing, 71 = code-
    review-and-refactoring, 72 = requirements-engineering — the file
    numbering IS the id source).
repainting_findings: review-class routing mandates the repainting-and-lookahead audit (12).
mtf_findings: none in scope.
runtime_performance_findings: perf routing (69) gated to perf/limits symptom classes.
numerical_stability_findings: none in scope.
duplicate_findings: none.
overlap_findings:
  - meta/skill_router.md (architecture): the skill is the Skill-form
    counterpart of the documented Router algorithm — no architecture
    modification; no executable routing logic was implemented in Import
    Mode. relationship: complementary. recommended_action: no_action
  - pine-version-intelligence (batch-001): 06 in every code-touching set —
    complementary. recommended_action: dependency_relationship
provenance_note:
  - Created by the source as the routing brain for the 77-skill library;
    map-extension rule (Decisions Log) preserved.
ambiguities: []
missing_information: []
blockers: []
changes_made_during_normalization:
  - Reorganized source sections into the standard Skill template (structure only).
  - Added Persian trigger renderings.
  - Two drafting artifacts introduced and immediately corrected during
    normalization (a malformed table row + duplicated sections) — final
    file verified clean; original source untouched.
  - No rule added, removed, or semantically reworded.
source_preservation_status: preserved (original untouched in skills/incoming/)
registry_update_status: registered (batch-008)
recommended_action: no_action
next_action: eligible for Router discovery in future Router phase.
```
