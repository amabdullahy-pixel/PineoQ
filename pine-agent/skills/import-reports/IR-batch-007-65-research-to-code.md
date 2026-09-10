# Import Report — IR-batch-007-65

```yaml
report_id: IR-batch-007-65
import_batch: batch-007
original_filename: 65-research-to-code.md
source_path: skills/incoming/65-research-to-code.md
proposed_skill_id: research-to-code
final_skill_id: research-to-code
final_status: normalized
activation_status: eligible
primary_layer: RESEARCH
domains: [research-methods, implementation-planning]
extracted_triggers:
  english: [research to production pipeline, stage gates artifact,
    signal path diff, pine compatible model, warm-up state inventory,
    productionization divergence]
  persian: [از پژوهش تا کد, دروازه‌های مرحله‌ای, تبدیل مدل به پیاده‌سازی]
dependencies:
  mandatory: []
  optional: [hypothesis-and-formula-engineering, pine-code-architecture,
    pine-performance-engineering, repainting-and-lookahead,
    mtf-engineering, data-integrity, backtesting-science,
    drawing-and-visualization, performance-metrics]
validation_results:
  unique_skill_id: pass
  clear_purpose: pass
  justified_primary_layer: pass
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
  - Translation-step semantics (float precision, conditional ta.*
    restructuring to global scope, non-repaint HTF pattern, verified
    window-function mapping) — all consistent with numerical-methods,
    pine-language-core, and repainting/mtf verified inventories.
  - var/varip state-inventory choice consistent with execution-model facts.
repainting_findings: HTF terms must pass the non-repaint pattern or be explicitly marked research-only-repainting; repaint audit is validation-gate item.
mtf_findings: HTF mapping routed through mtf-engineering.
runtime_performance_findings: algorithm stage mandates budget analysis (bounded loops, array trimming) before Pine — pine-performance-engineering handoff.
numerical_stability_findings: exact Pine float semantics substitution step registered.
duplicate_findings: none.
overlap_findings:
  - research-methodology (same batch): 62 governs the scientific loop
    (is it true?), 65 governs the promotion pipeline (ship it faithfully) —
    sequential, related_but_distinct. recommended_action: keep_separate
  - pine-code-architecture (same batch): production-structure executor at
    stage 6. relationship: complementary.
    recommended_action: dependency_relationship
provenance_note:
  - Stage-gate model formalized by the source; cross-linked checks
    consistent with verified inventories.
ambiguities: []
missing_information: []
blockers: []
changes_made_during_normalization:
  - Reorganized source sections into the standard Skill template (structure only).
  - Added Persian trigger renderings.
  - No rule added, removed, or semantically reworded.
source_preservation_status: preserved (original untouched in skills/incoming/)
registry_update_status: registered (batch-007)
recommended_action: no_action
next_action: eligible for Router discovery in future Router phase.
```
