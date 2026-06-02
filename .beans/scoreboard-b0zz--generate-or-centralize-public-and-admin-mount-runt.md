---
# scoreboard-b0zz
title: Generate or centralize public and admin mount runtime
status: todo
type: task
priority: normal
tags:
    - runtime
    - generated-soon
created_at: 2026-06-02T10:04:05Z
updated_at: 2026-06-02T10:04:05Z
parent: scoreboard-d0g1
blocked_by:
    - scoreboard-eulm
---

## Problem

src/public_app.gleam and src/admin_app.gleam duplicate the same browser app runtime shape: parse current route, initialize page model, consume hydration, connect websocket, listen for shell navigation, listen for popstate, apply server frames, and render the shell.

The duplication is type-safe but noisy. It makes the unified app feel like two mini apps glued together.

## Direction

Reduce public/admin mount duplication while preserving concrete mount types. Prefer generated_soon helpers or generator-shaped code over a clever abstraction that fights Gleam types. If full centralization would make the code harder to read, capture that and keep only the low-risk pieces generic.

## Acceptance criteria

- Shared browser mount mechanics live in src/generated_soon/ or another clearly generated-shaped boundary.
- public_app.gleam and admin_app.gleam retain only mount-specific decisions: route family, page type, shared state, shell wiring, and page-specific navigation mapping.
- Hydration and websocket startup behavior is unchanged.
- Browser smoke covers direct load, hydration, SPA navigation, back/forward, and admin route load.
