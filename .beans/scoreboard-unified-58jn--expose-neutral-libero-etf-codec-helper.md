---
# scoreboard-unified-58jn
title: Expose neutral Libero ETF codec helper
status: todo
type: task
priority: high
tags:
    - libero
    - chase
created_at: 2026-06-04T17:09:50Z
updated_at: 2026-06-04T17:10:59Z
parent: scoreboard-unified-wm8p
---

## What to build

Libero should generate a neutral ETF codec helper for the page-local contract set. The helper must not be typed around root app protocol modules such as api/to_client or api/to_server.

## Acceptance criteria

[ ] Libero output exposes server-safe decode and encode helpers that Rally can call from generated/rally/server_protocol.
[ ] Atom registration covers page-local request, result, and broadcast constructors without requiring stale root ToClient/ToServer wrappers.
[ ] Generated Libero files stay under src/generated/libero/**.
[ ] Scoreboard can delete generated/libero/to_client_codec.gleam and generated/libero/to_server_codec.gleam once Rally no longer imports them.

## Non-goals

Do not move ETF codec generation into Rally. Do not generate Proute or Rally files from Libero.
