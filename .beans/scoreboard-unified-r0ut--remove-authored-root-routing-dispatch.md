---
# scoreboard-unified-r0ut
title: Remove authored root routing dispatch
status: completed
type: epic
priority: high
tags:
    - rally
    - routing
    - chase
created_at: 2026-06-05T18:00:00Z
updated_at: 2026-06-05T19:02:20Z
---

## What to build

Remove route and page dispatch work from Scoreboard's authored root modules. The page tree and filenames are the author-facing routing surface. Proute owns route and page shape. Rally should consume Proute output and generate the mechanical glue around browser navigation, load dispatch, SSR, hydration, and push delivery.

Root authored modules should keep app policy and shell behavior: auth/session lookup, database/resource setup, document shell choices, shared client state, dark mode, and product broadcast meaning. They should not match generated route constructors, parse route params, wrap generated page messages by route, or decide which generated page constructor receives a broadcast.

## Audit findings

- `src/public_app.gleam` imports generated public routes/pages, parses paths, builds route values, stringifies route params, and maps page-local navigation messages to routes.
- `src/admin_app.gleam` imports generated admin routes/pages, parses paths, turns routes back into paths, and passes route-specific load selectors through navigation.
- `src/public_boot.gleam` and `src/admin_boot.gleam` are almost entirely handwritten route/page dispatch: browser load selection, SSR load selection, load result-to-page-message mapping, load error routing, and push/page constructor matching.
- `src/app_ssr.gleam` imports generated public/admin routes/pages to parse paths, turn routes back into paths, render generated page views, and invoke mount-specific boot helpers.
- `src/app_ws.gleam` joins every websocket to the root `"app"` topic, so broadcast page interest is currently decided later by root page dispatch rather than by page-owned subscriptions.

## Acceptance criteria

- Authored root modules no longer import generated route modules to perform page load, hydration, browser navigation, SSR, or push dispatch.
- Authored root modules no longer contain broad case expressions over generated route constructors or generated page constructors.
- Page interest in broadcasts is expressed through page-owned subscriptions/topics, not root page-constructor matching.
- Clean regeneration still works from empty generated output.
- Scoreboard validation passes: `gleam build --target erlang`, `gleam build --target javascript`, `TEMP=./tmp gleam test --target erlang`, boundary guard, websocket smoke, and browser smoke when browser behavior changes.

## Child beans

- `scoreboard-unified-n4vg`: Remove root browser navigation routing work.
- `scoreboard-unified-l0ad`: Generate load route and result-message adapters.
- `scoreboard-unified-p5sh`: Move broadcast interest to page topics.
- `scoreboard-unified-ssr2`: Remove SSR route composition from app root.
- `scoreboard-unified-grd1`: Add guards against authored root routing dispatch.

## Summary of Changes

Completed the routing-dispatch cleanup epic. Rally/Proute-generated glue now owns the route, load, SSR, browser navigation, hydration, and push dispatch mechanics, while Scoreboard root modules keep app-owned policy, shell, auth/session, database setup, and broadcast meaning. Added guard coverage to keep authored root/page modules from reintroducing generated route imports or generated route/page constructor dispatch.

## Validation

- `gleam build --target erlang`
- `gleam build --target javascript`
- `TEMP=./tmp gleam test --target erlang`
- `node test/boundary_guard_test.mjs`
- `node test/ws_result_smoke.mjs`
- `npm run test:browser`
- Clean regeneration in `../.tmp-rally-scoreboard-regen`: removed `src/generated`, ran `gleam run -m marmot`, `gleam run -m proute`, `gleam run -m rally load-rpc`, then built Erlang and JavaScript targets.

## Follow-up Fix

Regenerated Rally SSR after removing the remaining admin load callback leak. `src/app_ssr.gleam` now passes `AdminLoadHandlers(load_context: ...)`, and generated `server_ssr` owns the admin route-to-page load call. The boundary guard now rejects both public and admin SSR page-load callback adapters in app root code.

Validation:

- `gleam build --target erlang`
- `gleam build --target javascript`
- `TEMP=./tmp gleam test --target erlang`
- `node test/boundary_guard_test.mjs`
- `node test/ws_result_smoke.mjs`
- `npm run test:browser`
