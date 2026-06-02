---
# scoreboard-d0g1
title: Unwind split-shaped unified app code
status: todo
type: epic
priority: high
tags:
    - architecture
    - cleanup
created_at: 2026-06-02T10:03:33Z
updated_at: 2026-06-02T10:03:33Z
---

## Problem

The unified scoreboard app works, but it still has too much handwritten runtime glue. The codebase has too much app-level code for mount startup, browser hydration, websocket transport, route loading, and duplicated mount runtime.

The working behavior is valuable. The cleanup should keep the app green while gradually moving generic code into an explicit generated-soon boundary and shrinking app-authored modules.

## Direction

Use ../scoreboard-sc as an ergonomics reference, especially the way a page owns its model, data loading, update logic, and view. Keep the unified app architecture, but keep shrinking fossilized runtime boundaries.

Create src/generated_soon/ for generic code that should eventually be generated or owned by a library, but whose final generator/library boundary is not settled yet.

## Acceptance criteria

- The app still passes Gleam checks, tests, JS/Erlang builds, glinter, and browser smoke tests after each cleanup slice.
- Page modules become the main authored unit for page behavior.
- Views are collapsed into pages unless a view helper clearly earns a separate module.
- Generic runtime glue is either generated, moved under src/generated_soon/, or isolated behind a small app boundary.
- Public/admin duplication is reduced without losing mount-specific type safety.
- SSR hydration and client hydration keep using ETF payloads.
