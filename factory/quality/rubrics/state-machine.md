# rubric: state-machine
version: 1
applies_to: [builder, implementer]
weight_total: 100

## Dimensions
| id | dimension | weight | what to look for |
|----|-----------|--------|------------------|
| SM-1 | state_transitions | 30 | State changes follow valid transition paths, no impossible states |
| SM-2 | observable_correctness | 25 | Observable/reactive state properties update correctly and trigger dependent refresh |
| SM-3 | async_safety | 25 | Async operations handle cancellation, errors, and concurrent access |
| SM-4 | initial_state | 20 | Initial state is well-defined and consistent across all properties |

## Scoring
0.0 / 0.25 / 0.5 / 0.75 / 1.0 per dimension.
Weighted score = sum(score * weight) / weight_total.

## Fail Conditions
- SM-1 at 0.0 = automatic fail (invalid state transitions are logic errors).
- SM-3 at 0.0 = automatic fail (async safety violations cause data races).
- More than 3 issues at severity 0.25 or worse = automatic fail.

## Evaluator Instructions
- SM-1: Trace all state mutation paths. Score 1.0 if all transitions are valid. Score 0.5 if edge cases unhandled. Score 0.0 if impossible state reachable.
- SM-2: Verify observable/reactive state annotations and property mutation patterns. Score 1.0 if correct. Score 0.5 if updates work but are inefficient. Score 0.0 if mutations don't trigger observation.
- SM-3: Check for thread safety, proper isolation, and async task handling. Score 1.0 if fully correct. Score 0.5 if mostly safe with minor gaps. Score 0.0 if data race possible.
- SM-4: Verify all stored properties have sensible defaults. Score 1.0 if fully defined. Score 0.5 if optional properties used as implicit nil. Score 0.0 if initialization can leave inconsistent state.
