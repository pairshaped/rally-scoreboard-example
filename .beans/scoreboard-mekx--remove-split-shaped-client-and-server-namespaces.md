---
# scoreboard-mekx
title: Remove split-shaped client and server namespaces
status: todo
type: task
priority: normal
tags:
    - architecture
    - cleanup
created_at: 2026-06-02T10:04:31Z
updated_at: 2026-06-02T10:04:31Z
parent: scoreboard-d0g1
---

## Problem

The unified app still has src/client/* and src/server/* namespaces. Some modules there are legitimate browser/server target boundaries, but the names make the app read like the old split architecture.

This is partly cosmetic, but names shape future edits. If generic browser/server runtime glue stays under client/server, new work will keep landing in split-shaped buckets.

## Direction

After generic code has moved to src/generated_soon/ and scoreboard_unified.gleam has been split, rename or rehome the remaining modules so their names reflect ownership:

- app-owned API handlers stay app-owned
- generated-shaped runtime glue lives under generated_soon
- target-specific FFI boundaries use names that describe the boundary, not old package roles
- server auth policy and SQL command handling remain clearly application code

## Acceptance criteria

- Remaining src/client and src/server modules are either deleted, renamed, or explicitly justified.
- Import paths make unified ownership clear.
- No generated code is manually edited unless that is already part of the agreed generated-soon bridge.
- Full validation and browser smoke pass.
- The cleanup does not hide real target-specific constraints.
