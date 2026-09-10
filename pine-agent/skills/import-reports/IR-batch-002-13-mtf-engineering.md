# Import Report — IR-batch-002-13

```yaml
report_id: IR-batch-002-13
import_batch: batch-002
original_filename: 13-mtf-engineering.md
source_path: skills/incoming/13-mtf-engineering.md
proposed_skill_id: mtf-engineering
final_skill_id: mtf-engineering
final_status: normalized
activation_status: eligible
primary_layer: IMPLEMENTATION
domains: [mtf, data-acquisition]
extracted_triggers:
  english: [request.security, request.security_lower_tf, higher timeframe request,
    lower timeframe intrabars, HTF confirmation lag, gaps_on gaps_off,
    dynamic requests, intrabar budget]
  persian: [دیتای چند تایم‌فریم, تایم‌فریم بالاتر, اینتربار, تاخیر تایید HTF,
    بودجه اینتربار]
dependencies:
  mandatory: []
  optional: [repainting-and-lookahead, data-integrity, multi-symbol-engineering, pine-v6]
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
  - request.security/security_lower_tf semantics, gaps/lookahead mapping,
    dynamic-requests default (v6), 40/64 request cap, ≤127 tuple elements —
    all consistent with batch-001-verified facts (pine-v6, release notes) and
    official other-timeframes docs cited by the source.
  - Intrabar budget numbers (100K/125K/200K) are plan-gated; recorded with the
    shared re-verify caveat.
repainting_findings:
  - Request-pattern taxonomy (confirmed/live/lagged) with explicit repaint
    consequences per pattern; LTF-via-security forbidden pattern captured.
mtf_findings:
  - This IS the MTF skill; synchronization pitfalls (confirmation lag, session
    anchoring, calc_bars_count) registered.
runtime_performance_findings: request/intrabar budgets recorded as feasibility constraints.
numerical_stability_findings: none in scope.
duplicate_findings: none.
overlap_findings:
  - repainting-and-lookahead (batch-002): audit vs acquisition;
    relationship: complementary. recommended_action: keep_separate
  - multi-symbol-engineering (batch-002): symbol choice vs TF mechanics;
    relationship: complementary. recommended_action: keep_separate
ambiguities: []
missing_information: []
blockers: []
changes_made_during_normalization:
  - Reorganized source sections into the standard Skill template (structure only).
  - Added Persian trigger renderings.
  - No rule added, removed, or semantically reworded.
source_preservation_status: preserved (original untouched in skills/incoming/)
registry_update_status: registered (batch-002)
recommended_action: no_action
next_action: eligible for Router discovery; resolves batch-001
  pending-dependency pointers from tradingview-execution-model and
  drawing-and-visualization.
```
