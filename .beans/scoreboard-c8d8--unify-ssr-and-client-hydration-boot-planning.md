---
# scoreboard-c8d8
title: Unify SSR and client hydration boot planning
status: todo
type: task
priority: high
tags:
    - ssr
    - hydration
    - etf
created_at: 2026-06-02T10:04:13Z
updated_at: 2026-06-02T10:04:13Z
parent: scoreboard-d0g1
blocked_by:
    - scoreboard-kqjf
---

## Problem

SSR hydration currently works, but the server and browser paths hand-maintain too much parallel logic. The server builds hydration messages and SSR page models, while the browser consumes ETF hydration and then applies ToClient messages through a separate reducer path.

This is exactly the kind of code that should eventually be generated from routes, pages, and API contracts.

## Direction

Create one generated-shaped boot plan for each mount/route that can drive both server SSR hydration and client startup. The payload must remain ETF ToClient data, not JSON.

The goal is to make route boot behavior explicit and remove duplicated handwritten mappings in scoreboard_unified.gleam and client/to_client.gleam where possible.

## Acceptance criteria

- Direct HTTP route rendering and browser startup agree on the same initial ToClient messages.
- Data-backed direct loads do not send duplicate initial websocket load requests.
- Hydration continues to use Libero-generated ETF codecs.
- Invalid or missing hydration still falls back to normal client loading.
- The implementation does not introduce a second JSON hydration protocol.
- Tests or smoke coverage prove direct load, hydration, and websocket updates still work.
