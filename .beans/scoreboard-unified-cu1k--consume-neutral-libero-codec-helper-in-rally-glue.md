---
# scoreboard-unified-cu1k
title: Consume neutral Libero codec helper in Rally glue
status: todo
type: task
priority: high
tags:
    - rally
    - chase
created_at: 2026-06-04T17:10:02Z
updated_at: 2026-06-04T17:10:02Z
parent: scoreboard-unified-wm8p
blocked_by:
    - scoreboard-unified-58jn
---

## What to build

Update Rally load-rpc generation so generated/rally/server_protocol calls the neutral Libero ETF helper instead of root to_client_codec/to_server_codec wrappers. Regenerate Scoreboard and delete the obsolete root API/domain and root codec wrapper files that become unused.

## Acceptance criteria

[ ] generated/rally/server_protocol imports no generated/libero/to_client_codec or generated/libero/to_server_codec modules.
[ ] generated/rally/server_protocol still decodes page-local requests and encodes load/save result and broadcast frames.
[ ] src/api/to_client.gleam, src/api/to_server.gleam, and stale src/api/domain modules are deleted from Scoreboard when no live import remains.
[ ] Stale root imports disappear from src/generated/libero/codec_ffi.mjs after regeneration.
[ ] Scoreboard erlang build, javascript build, erlang tests, websocket smoke, and browser smoke pass.

## Non-goals

Do not generate Libero-owned codec files from Rally. Do not move app-owned SSR result mapping or broadcast policy into Rally.
