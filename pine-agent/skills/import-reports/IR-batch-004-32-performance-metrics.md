# Import Report — IR-batch-004-32

```yaml
report_id: IR-batch-004-32
import_batch: batch-004
original_filename: 32-performance-metrics.md
source_path: skills/incoming/32-performance-metrics.md
proposed_skill_id: performance-metrics
final_skill_id: performance-metrics
final_status: normalized
activation_status: eligible
primary_layer: QUANT
domains: [performance-metrics, evaluation]
extracted_triggers:
  english: [expectancy, profit factor, win rate, Sharpe Sortino Calmar,
    recovery factor, MAE MFE, strategy.netprofit, custom metrics dashboard]
  persian: [شاخص‌های عملکرد, نسبت سود به ضرر, نرخ برد, شارپ و سورتینو]
dependencies:
  mandatory: []
  optional: [financial-mathematics, statistical-testing,
    drawing-and-visualization, strategy-engine]
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
  - Native strategy.* names (netprofit/grossprofit/closedtrades family/
    max_drawdown(_percent)/closedtrades.* accessors) verified by source
    against v6 reference; consistent with batch-001 strategy-engine
    introspection facts and batch-003 risk-management re-verifications
    (max_drawdown_percent confirmed on official docs).
  - Negative claim preserved: NO built-in Sharpe/Sortino/Calmar functions in
    code (tester-report only) — verify-before-use gate.
  - Sharpe/Sortino/PF conventions cross-checked against the cited TradingView
    support articles (as source states).
repainting_findings: none in scope.
mtf_findings: none in scope.
runtime_performance_findings: monthly-bucket arrays O(1) per bar — consistent with incremental-state guidance.
numerical_stability_findings: n>0 and grossloss≠0 guards recorded as mandatory.
duplicate_findings: none.
overlap_findings:
  - strategy-engine (batch-001): introspection accessors vs metric computation;
    relationship: complementary. recommended_action: keep_separate
  - backtesting-science (pending, 51): evaluation methodology expected there;
    relationship: expected related_but_distinct. recommended_action: no_action
ambiguities: []
missing_information: []
blockers: []
changes_made_during_normalization:
  - Reorganized source sections into the standard Skill template (structure only).
  - Added Persian trigger renderings.
  - No rule added, removed, or semantically reworded.
source_preservation_status: preserved (original untouched in skills/incoming/)
registry_update_status: registered (batch-004)
recommended_action: no_action
next_action: eligible for Router discovery; resolves batch-003 pending
  pointers from financial-mathematics and probability.
```
