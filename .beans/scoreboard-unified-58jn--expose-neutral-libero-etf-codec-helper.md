---
# scoreboard-unified-58jn
title: Expose neutral Libero ETF codec helper
status: completed
type: task
priority: high
tags:
    - libero
    - chase
created_at: 2026-06-04T17:09:50Z
updated_at: 2026-06-05T04:01:24Z
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



Completed by the current Rally/Libero load-rpc generation path. Generated Libero output now provides neutral ETF helpers under src/generated/libero/etf.gleam plus rpc_decoders/rpc_wire/rpc_atoms. Scoreboard no longer has generated/libero/to_client_codec.gleam or generated/libero/to_server_codec.gleam, and no src/api root protocol directory remains.

Verified with:

• rg found no generated/libero/to_client_codec or generated/libero/to_server_codec imports
• rg found generated/rally/client_protocol.gleam and generated/rally/server_protocol.gleam import generated/libero/etf
• src/generated/libero contains dispatch.gleam, etf.gleam, rpc_decoders.gleam, rpc_decoders_ffi.mjs, rpc_contract.json, generated@rpc_atoms.erl, generated@rpc_wire.erl
• gleam build --target erlang
• gleam build --target javascript
• gleam test --target erlang
• node test/boundary_guard_test.mjs
• node test/ws_result_smoke.mjs
• SCOREBOARD_BASE_URL=http://localhost:8107 node test/browser_smoke.mjs
