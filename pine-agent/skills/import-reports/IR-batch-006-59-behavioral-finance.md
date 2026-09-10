# Import Report — IR-batch-006-59

```yaml
report_id: IR-batch-006-59
import_batch: batch-006
original_filename: 59-behavioral-finance.md
source_path: skills/incoming/59-behavioral-finance.md
proposed_skill_id: behavioral-finance
final_skill_id: behavioral-finance
final_status: normalized
activation_status: eligible
primary_layer: RESEARCH
domains: [behavioral, market-context]
extracted_triggers:
  english: [loss aversion disposition effect, herding anchoring recency bias,
    behavioral market signature, contrarian filter design,
    funding rate sentiment]
  persian: [رفتارشناسی بازار, سوگیری‌های رفتاری, اثر واگذاری]
dependencies:
  mandatory: []
  optional: [market-psychology, liquidity-and-price-structure,
    quantitative-analysis, walk-forward-and-validation, trade-management,
    performance-metrics, volume-analysis]
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
  - strategy.closedtrades accessors for the disposition audit — consistent
    with strategy-engine (batch-001) and performance-metrics (batch-004)
    verified accessors.
repainting_findings: none in scope (bias proxies operate on confirmed data per their source skills).
mtf_findings: none in scope.
runtime_performance_findings: none in scope.
numerical_stability_findings: none in scope.
duplicate_findings: none.
overlap_findings:
  - market-psychology (same batch): 59 = bias definitions + own-trade
    audits; 60 = crowd-state proxies + detection patterns.
    related_but_distinct. recommended_action: keep_separate
  - liquidity-and-price-structure (batch-005): loss-aversion → sweep
    signature consumed. relationship: complementary.
    recommended_action: dependency_relationship
provenance_note:
  - Bias definitions = academic provenance (CFA Institute / Decision Lab,
    Kahneman–Tversky) — source-declared, preserved as such; proxy table vs
    TradingView funding-rate support article. NOT TradingView documentation
    authority for the psychology content.
ambiguities: []
missing_information: []
blockers: []
changes_made_during_normalization:
  - Reorganized source sections into the standard Skill template (structure only).
  - Added Persian trigger renderings.
  - One mojibake artifact in the normalized file's Persian trigger list
    corrected at write time («رفتارشناسی بازار»); original source untouched;
    correction recorded in the skill's Import Notes.
  - No rule added, removed, or semantically reworded.
source_preservation_status: preserved (original untouched in skills/incoming/)
registry_update_status: registered (batch-006)
recommended_action: no_action
next_action: eligible for Router discovery in future Router phase.
```
