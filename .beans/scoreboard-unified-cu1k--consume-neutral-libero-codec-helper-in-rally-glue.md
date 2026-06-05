---
# scoreboard-unified-cu1k
title: Consume neutral Libero codec helper in Rally glue
status: completed
type: task
priority: high
tags:
    - rally
    - chase
created_at: 2026-06-04T17:10:02Z
updated_at: 2026-06-05T04:01:24Z
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



Completed by the current generated Rally glue. generated/rally/server_protocol.gleam imports generated/libero/etf and uses local decode_any/encode_any helpers. It does not import generated/libero/to_client_codec, generated/libero/to_server_codec, api/to_client, or api/to_server. The obsolete root API directory and root codec wrappers are absent after clean regeneration.

Verified with:

• rg found no generated/libero/to_client_codec, generated/libero/to_server_codec, api/to_client, or api/to_server references
• generated/rally/server_protocol.gleam still decodes page-local requests and encodes load/save result and push frames
• Clean regeneration after deleting src/generated/rally and src/generated/libero
• gleam build --target erlang
• gleam build --target javascript
• gleam test --target erlang
• node test/boundary_guard_test.mjs
• node test/ws_result_smoke.mjs
• SCOREBOARD_BASE_URL=http://localhost:8107 node test/browser_smoke.mjs
