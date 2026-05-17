# rubric: unbounded-growth
version: 1
applies_to: [builder, implementer]
weight_total: 100

## Dimensions
| id | dimension | weight | what to look for |
|----|-----------|--------|------------------|
| UG-1 | collection_bounds | 35 | Arrays, dictionaries, and sets have bounded growth or cleanup |
| UG-2 | resource_lifecycle | 30 | Subscriptions, observers, and tasks are properly cancelled/cleaned up |
| UG-3 | cache_policy | 20 | Any caching has size limits and eviction |
| UG-4 | leak_potential | 15 | No strong reference cycles, prevent memory leaks in closures and callbacks |

## Scoring
0.0 / 0.25 / 0.5 / 0.75 / 1.0 per dimension.
Weighted score = sum(score * weight) / weight_total.

## Fail Conditions
- UG-1 at 0.0 = automatic fail (unbounded collections are memory leaks).
- More than 3 issues at severity 0.25 or worse = automatic fail.

## Evaluator Instructions
- UG-1: Check every collection that grows. Score 1.0 if all have bounds or cleanup. Score 0.5 if most bounded but one unbounded in low-frequency path. Score 0.0 if collection grows without limit in a hot path.
- UG-2: Check for observation/subscription cleanup in destructor or component cleanup lifecycle. Score 1.0 if all cleaned up. Score 0.5 if cleanup exists but timing is wrong. Score 0.0 if subscriptions leak.
- UG-3: Check caches for maxSize or TTL. Score 1.0 if policy exists. Score 0.5 if implicit limit via data source. Score 0.0 if unlimited cache.
- UG-4: Check closures and callbacks to prevent memory leaks from reference cycles. Score 1.0 if correct. Score 0.5 if unnecessary weak captures. Score 0.0 if strong reference cycle exists.
