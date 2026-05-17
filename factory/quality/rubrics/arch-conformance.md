# rubric: arch-conformance
version: 1
applies_to: [builder, implementer, wirer]
weight_total: 100

## Dimensions
| id | dimension | weight | what to look for |
|----|-----------|--------|------------------|
| AC-1 | import_compliance | 30 | All imports match allowed-imports.json for the file's layer |
| AC-2 | boundary_respect | 30 | No cross-layer references (domain does not import views, views do not import other features) |
| AC-3 | file_scope | 20 | Changes stay within declared file whitelist |
| AC-4 | dependency_direction | 20 | Dependencies flow downward (views -> domain -> shared), never upward |

## Scoring
0.0 / 0.25 / 0.5 / 0.75 / 1.0 per dimension.
Weighted score = sum(score * weight) / weight_total.

## Fail Conditions
- Any dimension at 0.0 = automatic fail regardless of weighted score.
- More than 3 issues at severity 0.25 or worse = automatic fail.

## Evaluator Instructions
- AC-1: Check every import statement against allowed-imports.json. Score 1.0 if all comply. Score 0.0 if any banned import found.
- AC-2: Check for references across feature boundaries. Score 1.0 if clean. Score 0.5 if indirect reference via shared. Score 0.0 if direct cross-feature import.
- AC-3: Verify diff only touches files in the item's declared scope. Score 1.0 if clean. Score 0.0 if any out-of-scope change.
- AC-4: Trace import graph direction. Score 1.0 if all downward. Score 0.25 if upward reference exists. Score 0.0 if circular dependency.
