# Import Report — IR-batch-006-57

```yaml
report_id: IR-batch-006-57
import_batch: batch-006
original_filename: 57-market-microstructure.md
source_path: skills/incoming/57-market-microstructure.md
proposed_skill_id: market-microstructure
final_skill_id: market-microstructure
final_status: normalized
activation_status: eligible
primary_layer: RESEARCH
domains: [market-context, execution]
extracted_triggers:
  english: [bid ask spread pine, order flow footprint,
    slippage market impact, futures point value,
    continuous contract rollover, syminfo.type branching]
  persian: [ریزساختار بازار, اسپرد و نقدینگی, ارزش پوینت فیوچرز]
dependencies:
  mandatory: []
  optional: [strategy-engine, backtesting-science,
    multi-symbol-engineering, volume-analysis, asset-class-specialization,
    liquidity-and-price-structure]
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
  - bid/ask 1T-only semantics RE-VERIFIED at import (official
    chart-information docs: "On tick charts that use the '1T' timeframe,
    scripts can also use the bid and ask variables"; na elsewhere
    corroborated by release notes + multiple independent sources).
  - request.footprint() (2026-01, Premium/Ultimate) consistent with the
    batch-001 release-notes verification (skills 05/15).
  - request.security_lower_tf intrabar proxies consistent with
    mtf-engineering (batch-002).
  - "Negative claims (verify-before-use): NO live order book/depth, NO true
    historical bid/ask series, NO queue position, NO iceberg detection in
    Pine."
  - syminfo.pointvalue / request.currency_rate / continuous-contract
    back-adjustment semantics — source-verified vs official docs,
    consistent with the verified inventory.
repainting_findings: bid/ask are live-tick values (realtime-only); historical spread logic impossible — documented as an access limit, not a repaint mode.
mtf_findings: footprint/lower-tf proxies carry explicit request budgets (multi-symbol-engineering).
runtime_performance_findings: intrabar proxy budgets registered.
numerical_stability_findings: P&L math (Δpoints × pointvalue × qty) — exact integer-safe point values documented for futures.
duplicate_findings: none.
overlap_findings:
  - asset-class-specialization (same batch): class semantics shared — 57
    owns execution/access semantics, 58 owns porting workflow.
    relationship: complementary. recommended_action: keep_separate
  - strategy-engine / backtesting-science: fill mechanics + cost realism
    consumers. relationship: complementary.
    recommended_action: dependency_relationship
provenance_note:
  - Pine access claims verified against official docs (source + import
    re-verification 2026-09); auction-theory practice recorded as method
    provenance.
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
