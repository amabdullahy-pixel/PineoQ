# Import Report — IR-batch-006-54

```yaml
report_id: IR-batch-006-54
import_batch: batch-006
original_filename: 54-overfitting-and-robustness.md
source_path: skills/incoming/54-overfitting-and-robustness.md
proposed_skill_id: overfitting-and-robustness
final_skill_id: overfitting-and-robustness
final_status: normalized
activation_status: eligible
primary_layer: RESEARCH
domains: [backtesting, robustness]
extracted_triggers:
  english: [curve fitting, overfitting, robustness battery,
    parameter stability, multiple testing false positive, trial ledger]
  persian: [بیش‌برازش, استحکام استراتژی, منحنی برازش]
dependencies:
  mandatory: []
  optional: [walk-forward-and-validation, monte-carlo-and-resampling,
    position-sizing, regime-detection, backtesting-science,
    pine-code-architecture]
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
  - No platform-API claims; MC robustness routed through
    monte-carlo-and-resampling (batch-003) verified patterns
    (math.random seeding, bootstrap).
repainting_findings: none in scope.
mtf_findings: none in scope.
runtime_performance_findings: MC/bootstrap budgets per monte-carlo-and-resampling (registered batch-003).
numerical_stability_findings: none in scope.
duplicate_findings: none.
overlap_findings:
  - statistical-testing (batch-003): resolves the batch-003 parked candidate
    {25↔54} — multiple-testing math (Bonferroni-style tightening) vs test
    primitives. relationship: complementary.
    recommended_action: dependency_relationship
  - monte-carlo-and-resampling (batch-003): resolves its pending
    optional-dependency pointer to this skill. relationship: complementary.
    recommended_action: dependency_relationship
provenance_note:
  - Deployment thresholds (≥100 trades, PF ≥ 1.3, ≥50% OOS retention)
    preserved as suggested defaults to falsify per system (source-declared).
ambiguities: []
missing_information: []
blockers: []
changes_made_during_normalization:
  - Reorganized source sections into the standard Skill template (structure only).
  - Added Persian trigger renderings.
  - No rule added, removed, or semantically reworded.
source_preservation_status: preserved (original untouched in skills/incoming/)
registry_update_status: registered (batch-006)
recommended_action: no_action
next_action: eligible for Router discovery in future Router phase.
```
