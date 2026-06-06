# Preserve Authoring Style

Rally-generated output and Rally-rewritten source should preserve stable Rally/Gleam house style.

Large modules use section comment headers when the regions are large enough to benefit from them:

```text
// TYPES
// INIT
// UPDATE
// BROADCAST
// VIEW
// EFFECTS
// HELPERS
```

Small modules do not need headers when headers add noise.

Imports are grouped by target first:

1. unannotated imports that compile on both targets
2. `@target(erlang)` imports
3. `@target(javascript)` imports

Groups are separated by a blank line. Within each target group, imports are sorted alphabetically. `gleam format` preserves these blank-line groups, so authored source should use the groups intentionally instead of leaving formatter-preserved spacing accidental.

`gleam format` owns the final import formatting. Rally should emit stable, readable imports and avoid semantic churn, but the formatter may re-sort imports within groups in ways Rally should not fight.

Rally should not emit random import order, collapse imports into one noisy block, or churn section layout when semantics did not change. Style stability is part of whether generated and transformed code feels trustworthy.
