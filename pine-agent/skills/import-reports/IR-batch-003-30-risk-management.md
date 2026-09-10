# Import Report — IR-batch-003-30

```yaml
report_id: IR-batch-003-30
import_batch: batch-003
original_filename: 30-risk-management.md
source_path: skills/incoming/30-risk-management.md
proposed_skill_id: risk-management
final_skill_id: risk-management
final_status: normalized
activation_status: eligible
primary_layer: IMPLEMENTATION
domains: [risk-control, strategies]
domains_note: >-
  source category is "Financial Math & Risk"; layer assigned from actual
  function — building risk controls into strategies with Pine APIs and
  patterns (implementation work), with quant/risk as secondary domain.
extracted_triggers:
  english: [risk per trade, daily loss limit, strategy.risk,
    drawdown accounting high-water mark, risk of ruin, exposure cap,
    correlated positions risk]
  persian: [مدیریت ریسک, حد ضرر روزانه, افت سرمایه, احتمال نابودی, سقف پوزیشن]
dependencies:
  mandatory: []
  optional: [strategy-engine, position-sizing, monte-carlo-and-resampling,
    multi-symbol-engineering]
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
  - VERIFICATION EVENT corroborated: source documents that an earlier pass
    falsely claimed strategy.risk.* was removed in v6, corrected by direct
    reference check. Import-time INDEPENDENT re-verification: official
    TradingView Strategies concepts page lists strategy.risk.max_drawdown() /
    max_intraday_loss() etc.; v6 reference index shows
    max_drawdown/max_intraday_filled_orders/max_intraday_loss/max_position_size
    (alphabetical run consistent with all six); strategy.max_drawdown_percent
    confirmed on the official Strategies page. A third-party blog repeating
    the removal claim identified as the false claim the source warned about.
  - strategy.fixed_loss_dollars preserved with the source's own
    verify-per-symbol caveat (recorded as ambiguity).
  - Margin semantics (v6 default 100%) consistent with strategy-engine
    (batch-001).
repainting_findings: none in scope.
mtf_findings: none in scope.
runtime_performance_findings: none in scope.
numerical_stability_findings: none in scope.
duplicate_findings: none.
overlap_findings:
  - strategy-engine (batch-001): emulator/margin depth vs risk-control design;
    relationship: complementary. recommended_action: keep_separate
  - position-sizing (pending import, 31): sizing math expected there —
    deliberate division of labor documented in both skills' triggers;
    relationship: complementary. recommended_action: dependency_relationship
ambiguities:
  - strategy.fixed_loss_dollars exact accepted constants: listed by source as
    present in reference; verify per symbol before relying (preserved verbatim).
missing_information: []
blockers: []
changes_made_during_normalization:
  - Reorganized source sections into the standard Skill template (structure only).
  - Layer classification decision (IMPLEMENTATION vs source category) recorded
    per import rules.
  - Added Persian trigger renderings.
  - Import-time re-verification results documented without altering any rule.
source_preservation_status: preserved (original untouched in skills/incoming/)
registry_update_status: registered (batch-003)
recommended_action: no_action
next_action: eligible for Router discovery in future Router phase.
```
