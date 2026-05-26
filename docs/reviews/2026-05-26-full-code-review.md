# Full Code Review: Scoreboard

Scoreboard is the golden example app for a potential Generator Framework. This review treats generated-looking code as part of the target: if the future generator snapshots this shape, these are the behaviors it will preserve.

This review is not a request to delete generated-surface code just because it is unused today. Keep generated code when it represents a Generator Framework surface we want to support. Fix it when it is stale, misleading, wired to the wrong source, or encodes bad runtime behavior. Delete it only if we decide the Generator Framework should not support that surface at all. That decision requires explicit product review and input from Dave.

The `.rally-generation-disabled` flag says to remove it when generator work resumes. The P1 section below is the minimum review queue to resolve before that flag comes out.

## What Is Working

- The shared API shape matches ADR 0006: one global wire graph under `shared/api`, with Mount boundaries expressed by user-owned app code and generated Mount modules.
- The receiver pattern matches ADR 0003 and ADR 0004: page receivers map `ToClient` into local messages, and Mount receiver hubs compose those handlers.
- `generated/runtime/db.gleam` has a sound shape for dev-only timed query logging, nested savepoint transactions, and standard SQLite pragmas.
- Birdie snapshots plus structural tests give future generator work a tight comparison loop for generated output.

## Before Generation Work Resumes

### P1: Browser Smoke Test Fails On Admin WebSocket Auth

`test/root_api_ws_smoke.mjs` runs the admin helper, but `test/mount_ws_client.mjs` opens `/admin/ws` without signing in. The server now rejects unauthenticated admin WebSocket upgrades in `server/src/generated/entry.gleam`.

Observed result: `node test/root_api_ws_smoke.mjs` fails at the admin Mount check, then hangs until the spawned server is killed.

Fix target: teach the smoke test to authenticate before opening `/admin/ws`, or add an explicit unauthenticated-admin rejection test and move authenticated admin flows through a signed-in path.

### P1: User-Owned Shell Files Are Dead At Runtime

`server/src/server/public/shell.html` and `server/src/server/admin/shell.html` are user-owned shell files per ADR 0006. The generated SSR handlers inline the same HTML/CSS as Gleam string literals instead of reading or deriving from those files.

This creates two copies of shell truth. Tests assert pieces of both, but the runtime never uses the user-owned files.

Fix target: the generator should read each Mount's shell file and either inline the generated output from it or serve/reference it through a clear runtime path.

### P1: SSR Is Shell-Only And Hydration Is Unwired

`server/src/generated/public/ssr_handler.gleam` and `server/src/generated/admin/ssr_handler.gleam` ignore route, server context, session id, hostname, and query. Every route serves the same shell and waits for the browser to open WebSocket state.

The client transport has `read_flags` and `read_client_shared_state`, but the SSR handlers never set those globals.

Fix target: generated SSR should exercise route-specific load, request context, authentication facts, flags, and client shared state hydration.

### P1: Server Wire FFI Is Generated From The Wrong Graph

`server/src/generated/server_generated_protocol_wire_ffi.erl` only declares encode/decode transforms for `server/admin/model.Model`, a backend type that should not cross the wire.

The correct generator target is for server wire FFI to mirror the client `codec_ffi.mjs` registry one-for-one: every `ToServer`, `ToClient`, and shared API domain constructor, with no backend types.

Current smoke flows still round-trip nested values in some paths via plain ETF, so this is not evidence that all nested values are broken. The bug is that the generated artifact is the wrong target for the future generator.

## Runtime Contract Gaps

### P2: Reconnect Drops Queued Commands Silently

`client/src/generated/transport_ffi.mjs` says pending commands stay queued across reconnect, but socket construction failure, close, and error all call `clearPending()`.

User-visible effect: a network blip during an admin score update can drop the click with no retry, no server error, and no client notice. The 50ms flush delay after open is the same class of problem: command ordering depends on timing instead of an explicit init acknowledgement.

Fix target: preserve queued sends until flushed or rejected with a visible client error, and gate command flush on a server acknowledgement that page init has completed.

### P2: Cross-Mount Commands No-Op

Public dispatch matches admin commands and returns `effect.none()`. Admin dispatch does the same for public commands.

This hides protocol misuse. A malformed or stale client can send the wrong command over the wrong Mount and get no error, no issue log, and no feedback.

Fix target: choose and document a generator policy: per-Mount sliced protocol types, wire error responses, or issue logging plus explicit drop.

### P2: Admin Auth Does Not Populate Request Context

The `/admin/ws` upgrade is gated, so this is not an unauthenticated admin exploit. The gap is that generated request context does not carry authenticated user facts after the gate.

`server/src/generated/admin/ws_handler.gleam` hard-codes `user_id: option.None` in `make_request_context`. Handler authorization and user logging have no authenticated identity to inspect.

Fix target: populate request context from authenticated session state before admin handlers run.

### P2: Logging Flags Have No Runtime Effect

`gleam.toml` enables `user_logging` and `issue_logging` for both Mounts. `generated/runtime/system_db.gleam` defines `log_user` and `log_issue`, and tests call the helpers directly.

No generated entry, WebSocket runtime, or dispatch path calls those functions. The test suite passes because direct helper tests do not require runtime integration, so this feature has no compile-time or test-time pressure today.

Fix target: when logging is enabled, generated runtime paths should write user logs for authenticated activity and issue logs for runtime failures according to ADR 0006.

### P2: Live Updates Are Not Actually Live

ADR 0005 and ADR 0006 describe server-originated `ToClient` values. Current WebSocket runtime can send command results back to the same socket, but it ignores `mist.Custom` messages and backend `Msg` only has `FromClient`.

There is no path for another process to publish a score update to all interested sockets.

Fix target: add connection lifecycle messages, subscription or interest tracking, and a server-originated fanout path through the same `ToClient` receiver pipeline.

### P2: Browser Runtime Globals Still Use Rally Names

`client/src/generated/transport_ffi.mjs` exposes `__RALLY_DEBUG__`, `__RALLY_MESSAGES__`, `__RALLY_WS__`, `__RALLY_FLAGS__`, and `__RALLY_CLIENT_SHARED_STATE__`.

The ADR carve-out for `rally` config names does not cover browser runtime globals. These are public debugging and hydration surface.

Fix target: rename those globals to runtime/framework names and update snapshots.

### P2: Two Route Types Per Mount Share One Concept

`shared/src/generated/<mount>/route.gleam` has `NotFound` with no payload. `server/src/generated/<mount>/router.gleam` has `NotFound(uri: Uri)`. Entry uses the server-local route type, while `RequestContext` and handlers use the shared route type.

The relationship is too easy to misunderstand, and the shared route cannot carry URI data for telemetry.

Fix target: pick one route shape, or rename the server-local type so its HTTP-only role is explicit.

## Documentation And Snapshot Drift

### P3: README Advertises Missing Admin Routes

The README lists `/admin/games/new` and `/admin/games/:id`, but the generated admin route union and routers only support sign-in routes and `/admin/games`.

Fix target: either add the routes and pages, or trim the README to the current app.

### P3: Local Dependency Docs Drift

The README says the local framework dependency is `../runtime`, while root `gleam.toml` still depends on `../rally`.

Fix target: update the docs, or rename the dependency when the package move happens.

### P3: ADR Generated File List Conflicts With Tests

ADR 0006 lists generated files such as `shared/src/generated/runtime/data.gleam` and `server/src/generated/runtime/dispatch.gleam`. The tests assert some of those files should not exist.

Fix target: update ADR 0006 to describe the intended current generated layout.

### P3: Admin Mount Route Root Is Implicit

The public Mount config sets `route_root = "/"`. The admin Mount config omits `route_root`, while `entry.gleam` hardcodes `/admin`.

Fix target: document and test the rule: required route root, default to `"/" <> namespace`, or inferred elsewhere.

### P3: Confirm Marmot Output Path

SQL input lives under `server/src/server/sql/games/*.sql`, but generated output is `server/src/generated/sql/server/games_sql.gleam`.

Fix target: run Marmot and confirm it produces this path. If it does, keep it. If not, the example is hand-fudging generated SQL output and snapshotting the wrong target.

## Post-Generation Polish

These are worth fixing, but they should not block generator contract work:

- Admin `NotFound` routes map to `/`, crossing into the public Mount.
- The admin router parses both `/admin/sign_in` and `/admin/sign_in/password` as `AdminSignInPassword`, while `entry.gleam` redirects `/admin/sign_in` before the router runs.
- `Mount0` and `Mount1` names hide the public/admin Mount meaning.
- `Noop` and `Notice` variants are dead.
- Public receiver code hand-rolls `append`.
- `is_signed_in` checks the route rather than authentication state.
- `AdjustHome(Int, Int, Int, Int)` and `AdjustAway(Int, Int, Int, Int)` use four unlabeled integers.
- `GamesLoadFailed` represents games, game detail, and standings failures.
- WebSocket page init matches PascalCase strings such as `"GamesId"` and `"AdminGames"`.
- The client has two dev signals: `window.__APP_ENV__` and debug globals.
- `codec.ensure_decoders` returns `True`, while decoder registration happens as module import side effects.
- Admin page handlers use inconsistent `#(model, event)` versus `#(model, effect.send_to_client(event))` structure.
- The repo has ADRs and a README, but no root `CONTEXT.md` for domain language.

## Verification

Passed:

- `gleam test` in root, shared, client, and server
- `gleam format --check` in root, shared, client, and server
- `gleam run -m glinter` in root, shared, client, and server

Failed:

- `node test/root_api_ws_smoke.mjs`

The smoke test failed on the admin WebSocket authentication mismatch and then hung until the spawned server process was killed.
