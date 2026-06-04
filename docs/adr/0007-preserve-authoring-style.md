# Preserve Authoring Style

Rally-generated output and Rally-rewritten source should preserve stable Rally/Gleam house style.

Large modules use section comment headers when the regions are large enough to benefit from them:

```text
// TYPES
// INIT
// UPDATE
// VIEW
// EFFECTS
// HELPERS
```

Small modules do not need headers when headers add noise.

Imports are grouped in this order:

1. generated modules
2. standard library modules
3. external package modules
4. app/root shared modules
5. page-local or sibling modules

Within each group, imports are sorted alphabetically.

`gleam format` owns the final import order. Rally should emit stable, readable imports and avoid semantic churn, but the formatter may re-sort imports or collapse groups in ways Rally should not fight.

Rally should not emit random import order, collapse imports into one noisy block, or churn section layout when semantics did not change. Style stability is part of whether generated and transformed code feels trustworthy.
