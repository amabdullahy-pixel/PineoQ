# Import Report — IR-batch-006-52

```yaml
report_id: IR-batch-006-52
import_batch: batch-006
original_filename: 52-optimization-and-calibration.md
source_path: skills/incoming/52-optimization-and-calibration.md
proposed_skill_id: optimization-and-calibration
final_skill_id: optimization-and-calibration
final_status: normalized
activation_status: eligible
primary_layer: RESEARCH
domains: [backtesting, optimization]
extracted_triggers:
  english: [parameter optimization, grid search random search,
    sensitivity analysis, parameter plateau, calibration vs optimization,
    no built-in optimizer]
  persian: [بهینه‌سازی پارامتر, تحلیل حساسیت, کالیبراسیون]
dependencies:
  mandatory: []
  optional: [overfitting-and-robustness, walk-forward-and-validation,
    pine-code-architecture, pine-version-intelligence]
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
  - "Negative claim (verify-before-use): NO built-in strategy parameter
    optimizer on TradingView (source: 3 independent doc checks). Preserved
    WITH the source's own needs-review flag — if TradingView ships one,
    re-verify via release notes (pine-version-intelligence, registered
    batch-001). Not silently generalized."
  - External auto-optimizers = ToS violation (account-ban risk) — preserved
    as a hard constraint.
repainting_findings: none in scope (optimizing on the evaluation window = leakage discipline, routed to walk-forward-and-validation).
mtf_findings: none in scope.
runtime_performance_findings: combinatorial explosion documented (k params × 5 values = 5^k manual runs).
numerical_stability_findings: none in scope.
duplicate_findings: none.
overlap_findings:
  - calculus-and-optimization (batch-002): resolves the batch-002 parked
    candidate {18↔52} — math foundations vs honest optimization practice.
    relationship: complementary. recommended_action: no_action (distinct
    scopes confirmed)
  - walk-forward-and-validation (same batch): OOS pairing mandatory for
    optimization. relationship: complementary.
    recommended_action: dependency_relationship
provenance_note:
  - No-optimizer finding source-verified 3× with an explicit re-check gate;
    recorded as designed uncertainty, not fact frozen in time.
ambiguities:
  - needs-review flag on platform-optimizer status (source-declared,
    preserved; re-check via pine-version-intelligence).
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
