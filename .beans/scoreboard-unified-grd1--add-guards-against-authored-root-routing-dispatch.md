---
# scoreboard-unified-grd1
title: Add guards against authored root routing dispatch
status: completed
type: task
priority: normal
tags:
    - rally
    - routing
    - diagnostics
created_at: 2026-06-05T18:00:00Z
updated_at: 2026-06-05T18:41:10Z
parent: scoreboard-unified-r0ut
---

## What to build

Add focused guard coverage so authored root routing dispatch does not creep back into Scoreboard while Rally/Proute generation removes it.

The guard should encode the authoring rule from the ADRs: routes are expressed through page filenames and paths. Authored root modules should not import generated route modules or match generated page constructors just to perform route, load, SSR, browser navigation, or push dispatch.

## Acceptance criteria

- A boundary or architecture guard checks authored root modules for forbidden generated route imports and broad route/page dispatch patterns.
- The guard allows generated code under `src/generated/**`.
- The guard allows page modules to mention generated Proute page wrappers in explanatory comments, but not to perform root routing work.
- The guard failure message points to the ADR routing rule and the offending file.
- The guard can be relaxed deliberately for a documented app-policy exception.

## Validation

- `node test/boundary_guard_test.mjs`
- `gleam build --target erlang`
- `gleam build --target javascript`

## Summary of Changes

Added boundary guard coverage for the ADR 0003 routing rule. The guard now checks authored root and page modules for generated route imports and generated route/page constructor dispatch while ignoring explanatory comments and allowing documented app-policy exceptions.
