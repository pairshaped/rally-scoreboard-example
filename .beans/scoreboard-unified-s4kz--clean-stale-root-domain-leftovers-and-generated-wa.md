---
# scoreboard-unified-s4kz
title: Clean stale root-domain leftovers and generated warnings
status: done
type: task
priority: normal
tags:
    - rally
    - chase
created_at: 2026-06-04T03:38:31Z
updated_at: 2026-06-05T01:20:00Z
parent: scoreboard-unified-wm8p
---

## What to build

Remove stale global-domain residue and warning noise left from the chase spike. The most visible examples are root API/domain shapes that no longer match page-local models and generated modules that emit known unused warnings.

This is not cosmetic. Warning churn and stale generated shapes make the framework feel less trustworthy and make it harder to see real regressions.

## Plan outline

- Remove stale fields such as root `GameDetail.scoring_summary` once no path uses them.
- Delete root API/domain constructors and helpers after page-local contracts replace them.
- Fix generated Libero dispatch warnings, including the unused `message` binding.
- Remove hand-edited generated artifacts that become obsolete once Rally generates the glue.
- Keep `gleam format` as the final authority on import ordering.
- Run the full chase validation suite.

## Acceptance criteria

- [x] Stale root-domain fields are gone.
- [x] Obsolete root API/domain modules are removed or reduced to only still-needed temporary bridge types.
- [x] Generated-code warnings that are in scope are fixed.
- [x] `gleam build --target javascript`, `gleam build --target erlang`, `gleam test`, and browser smoke pass.
- [x] No generated/import-format churn remains beyond what `gleam format` produces.



Started after Rally commit d8115f9 and chase commits 20b2841/9398a26 made the page-local load/save glue regeneration-safe. First pass will identify root API/domain shapes that no current route/workflow uses and warning noise that blocks clean validation output.



First cleanup pass removed the live root websocket fallback and shrank src/app_api.gleam to broadcast frame helpers only. Unit coverage now calls page-owned admin save handlers and public standings load directly instead of pinning the old root ToServer/ToClient bridge. Also fixed the generated admin_boot route import by making it JavaScript-targeted.

Remaining cleanup: root api/to_client, api/to_server, generated Libero root codecs, and generic Rally root helpers still exist because hydration/runtime compatibility code is still typed around ToClient. JavaScript build still reports existing empty-module warnings for server-only modules.



Second cleanup pass removed the root ToClient hydration fallback from public_app.gleam and admin_app.gleam. generated/rally/to_client_application.gleam now applies broadcast push frames only; root Response frames are ignored. Removed dead apply_message/apply_messages helpers from generated/rally/public_boot.gleam and generated/rally/admin_boot.gleam.

Validated with:

• gleam build --target erlang
• gleam build --target javascript
• gleam test --target erlang
• SCOREBOARD_BASE_URL=http://localhost:8103 node test/ws_result_smoke.mjs
• SCOREBOARD_BASE_URL=http://localhost:8104 node test/browser_smoke.mjs

Remaining root ToClient/ToServer references are isolated to Rally-generated generic compatibility helpers in client_protocol/client_transport/hydration/server_protocol, so the next deletion should be made in Rally load-rpc generation and then regenerated into the app.



Third cleanup pass moved the generic root-helper deletion into Rally load-rpc generation and regenerated chase. generated/rally/client_protocol.gleam, client_transport.gleam, hydration.gleam, and server_protocol.gleam no longer emit root ToClient/ToServer request/response/hydration helpers. The app-side to_client_application now only applies broadcast push frames.

Validated with:

• Rally `gleam build`
• Rally `gleam test --target erlang` (load-rpc snapshots accepted; existing JSON fixture failures remain because fixtures/json_protocol/build/packages/libero/gleam.toml is missing)
• Chase `gleam build --target erlang`
• Chase `gleam build --target javascript`
• Chase `gleam test --target erlang`
• SCOREBOARD_BASE_URL=http://localhost:8105 node test/ws_result_smoke.mjs
• SCOREBOARD_BASE_URL=http://localhost:8106 node test/browser_smoke.mjs


Fourth cleanup pass removed the dead shared status_badge helper from src/components/ui.gleam, which was the last authored UI import of root api/domain/game. Remaining root API/domain references are now isolated to stale Libero root codec output and Rally server_protocol codec-runtime imports, so deleting those modules belongs with the runtime dependency bean rather than this app-owned cleanup slice.

Validated with:

• gleam build --target erlang
• gleam build --target javascript



Fifth cleanup pass removed public websocket load wrappers from app_ws.gleam. Scoreboard now configures Rally's load RPC context as sqlight.Connection, and generated/rally/server_ws.gleam calls page-owned public load_wire functions directly while admin load/save authorization remains app-owned.

Validated with:

• Clean regeneration after deleting src/generated/rally and src/generated/libero
• gleam build --target erlang
• gleam build --target javascript
• gleam test --target erlang
• node test/boundary_guard_test.mjs
• node test/ws_result_smoke.mjs

Final validation pass added Playwright as the local browser-smoke dev dependency and ignored `node_modules/`. The full cleanup validation now passes in this workspace:

• gleam build --target erlang
• gleam build --target javascript
• TEMP=/home/daverapin/projects/gleam/rally-scoreboard-example/tmp gleam test --target erlang
• node test/boundary_guard_test.mjs
• node test/ws_result_smoke.mjs
• npm run test:browser



Twelfth cleanup pass moved test databases out of hardcoded `/tmp` and into `./tmp/test-db`, with `simplifile` declared as a dev dependency for directory setup. This removes the local stale-owned `/tmp/scoreboard-unified-*.db` blocker and restores full Erlang test validation when Birdie's temp file is also pointed at the repo tmp directory.

Validated with:

• gleam build --target erlang
• gleam build --target javascript
• TEMP=/home/daverapin/projects/gleam/rally-scoreboard-example/tmp gleam test --target erlang
• node test/boundary_guard_test.mjs
• node test/ws_result_smoke.mjs



Eleventh cleanup pass moved browser server-frame decoding into generated/rally/browser_app.gleam. Deleted root `src/to_client_application.gleam`; public/admin app roots now call generated `server_frame_effect` with app-owned push callbacks from public_boot/admin_boot. Broadcast meaning and page update decisions remain app-owned.

Validated with:

• gleam run -m rally -- load-rpc
• gleam build --target erlang
• gleam build --target javascript
• node test/boundary_guard_test.mjs
• node test/ws_result_smoke.mjs



Sixth cleanup pass removed public SSR load handler callbacks from app_ssr.gleam. Scoreboard now passes only load_context into generated/rally/server_ssr.gleam for public SSR loads; generated SSR glue calls page-owned load_wire functions directly for String/Int route args. Route-to-message selection remains app-owned for now.

Validated with:

• Clean regeneration after deleting src/generated/rally and src/generated/libero
• gleam build --target erlang
• gleam build --target javascript
• gleam test --target erlang
• node test/boundary_guard_test.mjs
• node test/ws_result_smoke.mjs



Seventh cleanup pass deleted unused root src/server_context.gleam and added a boundary guard to keep that dead framework scaffolding from returning.

Validated with:

• gleam build --target erlang
• gleam build --target javascript
• gleam test --target erlang
• node test/boundary_guard_test.mjs
• node test/ws_result_smoke.mjs



Eighth cleanup pass regenerated Rally browser glue and moved public/admin root browser load routing to generated/rally/browser_app.gleam. public_app.gleam and admin_app.gleam now call generated initial/load helpers; public_boot.gleam and admin_boot.gleam retain the app-owned load result message callbacks and broadcast behavior.

Validated with:

• gleam run -m rally -- load-rpc
• gleam build --target erlang
• gleam build --target javascript
• node test/boundary_guard_test.mjs
• node test/ws_result_smoke.mjs

Validation caveat: gleam test --target erlang is blocked in this workspace by stale /tmp/scoreboard-unified-*.db files owned by debian. The test helper hardcodes /tmp, so TEMP/TMPDIR cannot redirect it.



Ninth cleanup pass moved SSR load-route message callbacks from app_ssr.gleam into public_boot.gleam and admin_boot.gleam. app_ssr.gleam now handles request/session identity, document shell rendering, and server_ssr composition, while page boot adapters own route-to-page-message choices. Added a JavaScript target placeholder to app_ssr.gleam to remove the empty-module warning during JavaScript builds.

Validated with:

• gleam build --target erlang
• gleam build --target javascript
• node test/boundary_guard_test.mjs
• node test/ws_result_smoke.mjs

Validation caveat: gleam test --target erlang remains blocked by stale /tmp/scoreboard-unified-*.db files owned by debian.



Tenth cleanup pass moved `/_build/*` static asset file serving from Scoreboard's `app_assets.gleam` into `rally/runtime/static.gleam`. `app_assets.gleam` now owns only the app CSS string, and `scoreboard_unified.gleam` calls the Rally runtime helper for generated JavaScript/CSS files. Added JavaScript placeholders to the touched server-only modules to remove the empty-module warnings during JavaScript builds.

Validated with:

• gleam build --target erlang
• gleam build --target javascript
• node test/boundary_guard_test.mjs
• node test/ws_result_smoke.mjs
