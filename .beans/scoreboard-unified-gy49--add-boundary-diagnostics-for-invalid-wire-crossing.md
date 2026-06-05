---
# scoreboard-unified-gy49
title: Add boundary diagnostics for invalid wire crossings
status: completed
type: feature
priority: normal
tags:
    - rally
    - chase
created_at: 2026-06-04T03:38:31Z
updated_at: 2026-06-05T00:00:00Z
parent: scoreboard-unified-wm8p
---

## What to build

Add Rally diagnostics that make wire boundary mistakes humane. When a type or import crosses the wrong boundary, Rally should report which contract was checked, which type/import was invalid, and the path that caused the crossing.

This should enforce the chase rule: wire-crossing types may reference page-local types, approved shared wire types, primitives, and containers. Helper/service/query/business/display types may exist as behavior, but their owned shapes must not leak across the wire.

## Plan outline

- Implement boundary checks for page-local load/save request and response contracts.
- Walk transitive type references used by wire payloads.
- Distinguish allowed page-local types from helper/service/query/business/display types.
- Add the approved shared/root wire homes to the rule: `src/wire/**` and `src/broadcasts.gleam`.
- Emit diagnostics that include contract name, offending symbol, and reference path.
- Add negative tests for shared helper shapes, query row types, imported display types, and target-specific imports crossing the wrong side.

## Acceptance criteria

- [x] Invalid wire type references fail with a clear diagnostic.
- [x] Invalid imports across client/server boundaries fail with a clear diagnostic.
- [x] Diagnostics identify the contract, offending type/import, and how Rally reached it.
- [x] Valid page-local types, primitives, containers, and approved shared wire types pass.
- [x] Tests cover at least one transitive violation.

## Progress

- Added the first Rally diagnostic slice for direct type references in Rally-managed `ServerMsg`, `LoadResult`, and page-owned `GameUpdate` contracts.
- The diagnostic reports the contract, field path, and offending type reference.
- Valid page-local types, primitives, containers, `src/wire/**`, and `src/broadcasts.gleam` references are allowed.
- Extended the check to walk referenced page-local and shared wire type definitions transitively, with the reference path included in the diagnostic.
- Added Rally diagnostics for target-gated imports used by shared wire contracts, including the target-gated import and field path in the error.
- Added negative Rally tests for generated SQL row leaks and target-specific shared wire imports.
