---
# scoreboard-unified-xgn2
title: Use Marmot 1.7.2
status: completed
type: task
priority: normal
created_at: 2026-06-05T15:42:51Z
updated_at: 2026-06-05T15:45:19Z
---

Switch Rally/Scoreboard Marmot dependency declarations and manifests to the published 1.7.2 release instead of older/local development assumptions.

## Summary of Changes

- Updated Scoreboard's Marmot dev dependency requirement and manifest lock to `>= 1.7.2 and < 2.0.0`.
- Also bumped Rally and Rally RealWorld to require/lock Marmot `1.7.2`.
- Replaced the Marmot example's local `marmot = { path = ".." }` dev dependency with the published `>= 1.7.2 and < 2.0.0` package.
- Regenerated the Marmot example SQL modules and adjusted example tests for the `1.7.2` generated parameter shapes.
- Validation: Scoreboard Erlang/JavaScript builds; Rally build; Rally RealWorld build; Marmot examples `gleam format`, `gleam build`, and `gleam test`.
