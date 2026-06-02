---
# scoreboard-lh45
title: Split scoreboard_unified into focused app server modules
status: todo
type: task
priority: normal
tags:
    - server
    - cleanup
created_at: 2026-06-02T10:04:23Z
updated_at: 2026-06-02T10:04:23Z
parent: scoreboard-d0g1
---

## Problem

src/scoreboard_unified.gleam is carrying too many responsibilities: process startup, HTTP routing, static files, auth redirects, document shell rendering, CSS, SSR page rendering, hydration payload encoding, and SSR/hydration orchestration.

The file works, but it is too large to be the long-term app shape.

## Direction

After the generated-soon and hydration boundaries are clearer, split scoreboard_unified.gleam into focused app-owned modules. Keep workflows together. Do not create private wrapper functions or modules whose only job is to rename a single call.

Likely boundaries:

- app document/shell rendering
- HTTP route classification and redirects
- static file response helpers
- SSR/hydration entry points
- CSS asset text, or a better asset path if one exists

## Acceptance criteria

- scoreboard_unified.gleam becomes a readable entrypoint instead of a catch-all.
- Extracted modules own distinct responsibilities.
- No behavior changes to auth redirects, static assets, SSR output, hydration payloads, or websocket routing.
- Existing validation and browser smoke pass.
- The final shape is compared against ../scoreboard-sc/server/src/scoreboard_server.gleam and documented in the bean completion notes.
