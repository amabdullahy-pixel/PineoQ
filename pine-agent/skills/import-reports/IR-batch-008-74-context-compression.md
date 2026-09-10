# Import Report — IR-batch-008-74

```yaml
report_id: IR-batch-008-74
import_batch: batch-008
original_filename: 74-context-compression.md
source_path: skills/incoming/74-context-compression.md
proposed_skill_id: context-compression
final_skill_id: context-compression
final_status: normalized
activation_status: eligible
primary_layer: META
domains: [knowledge-management, agent-operations]
extracted_triggers:
  english: [context compression ladder, change only reasoning,
    diff based context budget, state tuple compression,
    re-anchor golden set, handoff between sessions]
  persian: [فشرده‌سازی زمینه, استدلال تغییرمحور, خلاصه‌سازی وضعیت]
dependencies:
  mandatory: []
  optional: [project-knowledge-management, pine-code-architecture,
    pine-debugging-and-testing, requirements-engineering,
    backtesting-science, asset-class-specialization]
validation_results:
  unique_skill_id: pass
  clear_purpose: pass
  justified_primary_layer: pass
  justified_primary_layer_detail: function = agent context economy —
    mirrors meta/context_loading_policy.md and config/token_policy.yaml.
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
  - State-tuple illustration and invariants are agent-side conventions —
    no platform-API claims; golden-set re-anchor routed to
    pine-debugging-and-testing (batch-007, import-verified tooling).
repainting_findings: change-only reasoning explicitly forbidden on repaint-critical paths without re-anchor — registered as a hard guard.
mtf_findings: none in scope.
runtime_performance_findings: none in scope (context budgets are agent-side).
numerical_stability_findings: none in scope.
duplicate_findings: none.
overlap_findings:
  - config/token_policy.yaml + meta/context_loading_policy.md
    (architecture): the skill is the Skill-form counterpart — consistent,
    no architecture modification. relationship: complementary.
    recommended_action: no_action
  - project-knowledge-management (same batch): references-vs-copies
    discipline. relationship: complementary.
    recommended_action: dependency_relationship
provenance_note:
  - Ladder + budget schema formalized by the source for agent workflows
    (method provenance).
ambiguities: []
missing_information: []
blockers: []
changes_made_during_normalization:
  - Reorganized source sections into the standard Skill template (structure only).
  - Added Persian trigger renderings.
  - No rule added, removed, or semantically reworded.
source_preservation_status: preserved (original untouched in skills/incoming/)
registry_update_status: registered (batch-008)
recommended_action: no_action
next_action: eligible for Router discovery in future Router phase.
```
