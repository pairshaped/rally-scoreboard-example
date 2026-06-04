---
# scoreboard-unified-s4kz
title: Clean stale root-domain leftovers and generated warnings
status: in-progress
type: task
priority: normal
tags:
    - rally
    - chase
created_at: 2026-06-04T03:38:31Z
updated_at: 2026-06-04T17:00:18Z
parent: scoreboard-unified-wm8p
blocked_by:
    - scoreboard-unified-qf1q
    - scoreboard-unified-4pk9
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

- [ ] Stale root-domain fields are gone.
- [ ] Obsolete root API/domain modules are removed or reduced to only still-needed temporary bridge types.
- [ ] Generated-code warnings that are in scope are fixed.
- [ ] `gleam build --target javascript`, `gleam build --target erlang`, `gleam test`, and browser smoke pass.
- [ ] No generated/import-format churn remains beyond what `gleam format` produces.

## Blocked by

- Remaining public load migration.
- Admin load/save migration.



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
