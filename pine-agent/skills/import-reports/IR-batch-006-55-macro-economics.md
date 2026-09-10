# Import Report — IR-batch-006-55

```yaml
report_id: IR-batch-006-55
import_batch: batch-006
original_filename: 55-macro-economics.md
source_path: skills/incoming/55-macro-economics.md
proposed_skill_id: macro-economics
final_skill_id: macro-economics
final_status: normalized
activation_status: eligible
primary_layer: RESEARCH
domains: [macro, market-context]
extracted_triggers:
  english: [request.economic, CPI inflation data, interest rate INTR,
    GDP unemployment macro series, step series macro data,
    economic calendar limitation]
  persian: [اقتصاد کلان, تورم و نرخ بهره, داده‌های اقتصادی]
dependencies:
  mandatory: []
  optional: [intermarket-analysis, multi-symbol-engineering,
    documentation-verification, falsification-and-counterexamples]
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
  - request.economic() RE-VERIFIED at import against the official support
    article (43000665359, fetched live): signature
    request.economic(country_code, field, gaps, ignore_invalid_symbol);
    ISO alpha-2 country codes + "EU" Euro-area aggregate; CPI/GDP field
    codes verbatim in the official table; the article's own example is
    request.economic("US", "GDP").
  - "Negative claim (verify-before-use): NO Pine access to FUTURE economic-
    calendar timestamps — request.economic is history only; event-risk
    windows manual. Preserved as a hard limit."
  - Step-series discipline (no short-window indicators on macro series) —
    source-declared, consistent with time-series-analysis conventions.
repainting_findings: none in scope (macro series are non-repainting by nature; step-series distortion is the relevant hazard).
mtf_findings: request-budget impact (per-country-per-field unique requests, cap 40 — multi-symbol-engineering).
runtime_performance_findings: request-budget accounting mandatory.
numerical_stability_findings: none in scope.
duplicate_findings: none.
overlap_findings:
  - intermarket-analysis (same batch): rates/CPI context ↔ market
    relationships. relationship: complementary.
    recommended_action: dependency_relationship
  - multi-symbol-engineering (batch-002): request-budget governance.
    relationship: complementary. recommended_action: dependency_relationship
provenance_note:
  - Field-code list preserved as pointer-to-official-article (full list too
    large to duplicate; consult-at-use discipline registered, consistent
    with token-efficiency policy).
ambiguities: []
missing_information:
  - Full field list lives in the official support article (by design — not
    duplicated here; verify specific codes at use time).
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
