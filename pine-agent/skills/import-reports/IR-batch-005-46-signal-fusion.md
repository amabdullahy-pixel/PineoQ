# Import Report — IR-batch-005-46

```yaml
report_id: IR-batch-005-46
import_batch: batch-005
original_filename: 46-signal-fusion.md
source_path: skills/incoming/46-signal-fusion.md
proposed_skill_id: signal-fusion
final_skill_id: signal-fusion
final_status: normalized
activation_status: eligible
primary_layer: RESEARCH
domains: [quant-methods, signal-design]
extracted_triggers:
  english: [weighted voting signals, ensemble confluence,
    contradiction detection, hierarchical fusion veto,
    Bayesian fusion likelihood ratio, combine indicators signals]
  persian: [تلفیق سیگنال‌ها, رأی‌گیری وزنی, تشخیص تناقض, تلفیق بیزی]
dependencies:
  mandatory: []
  optional: [probability, quantitative-analysis, regime-detection,
    monte-carlo-and-resampling]
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
  - No Pine-API-specific claims; fusion math operates on normalized series.
  - Bayesian LRs estimated from outcome arrays (labeled events) consistent
    with monte-carlo-and-resampling (batch-003) array patterns.
repainting_findings: fused votes/confluence zones must be built from confirmed data — inherits each voter's confirmation discipline.
mtf_findings: HTF voters must use the non-repaint pattern (mtf-engineering) before fusion.
runtime_performance_findings: voter count capped (3–6) — bounded loop budget.
numerical_stability_findings: posterior odds product on independent evidence only; tiny-sample LRs forbidden (≥100 labeled events).
duplicate_findings: none.
overlap_findings:
  - quantitative-analysis (same batch): normalization → fusion pipeline.
    relationship: complementary. recommended_action: dependency_relationship
  - regime-detection (same batch): Layer-1 hard gate consumed by fusion's
    hierarchy. relationship: complementary.
    recommended_action: dependency_relationship
  - statistical-testing (batch-003): resolves that skill's pending
    optional-dependency pointer to signal-fusion.
    relationship: complementary. recommended_action: dependency_relationship
provenance_note:
  - Weighted-voting/confluence/contradiction-table practice is quant
    engineering convention (source-declared); Bayes independence
    requirements consistent with probability (batch-003).
ambiguities: []
missing_information: []
blockers: []
changes_made_during_normalization:
  - Reorganized source sections into the standard Skill template (structure only).
  - Added Persian trigger renderings.
  - No rule added, removed, or semantically reworded.
source_preservation_status: preserved (original untouched in skills/incoming/)
registry_update_status: registered (batch-005)
recommended_action: no_action
next_action: eligible for Router discovery in future Router phase.
```
