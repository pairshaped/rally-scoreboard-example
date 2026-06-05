---
# scoreboard-unified-l0ad
title: Generate load route and result-message adapters
status: completed
type: task
priority: high
tags:
    - rally
    - routing
    - load-rpc
created_at: 2026-06-05T18:00:00Z
updated_at: 2026-06-05T15:34:08Z
parent: scoreboard-unified-r0ut
---

## What to build

Remove handwritten browser and SSR load route dispatch from `src/public_boot.gleam` and `src/admin_boot.gleam`. Generated Rally glue should consume Proute route/page output and page-owned load conventions to select the load request, call the server load adapter, hydrate, and wrap the result in the generated Proute page message.

## Current routing work to remove

- `public_boot.load_route` and `admin_boot.load_route` match generated route constructors.
- `public_boot.ssr_load_route` and `admin_boot.ssr_load_route` match generated route constructors and wrap generated page messages.
- Public load result adapters match routes to decide which page message receives `Loaded`.
- Load error routing maps generated routes to page-specific `LoadError` constructors.
- Route params are parsed or carried by root boot modules instead of generated glue.

## Acceptance criteria

- `public_boot.gleam` and `admin_boot.gleam` no longer contain load route selectors.
- Browser and SSR load dispatch are generated from Proute page identity and page-owned load contracts.
- Root routes remain real pages; any home-page delegation remains page-owned.
- Generated Rally code does not invent route aliases or generate replacement route/page types.
- Public pages no longer require root user code to keep load routing in sync when a route is added, renamed, or deleted.

## Validation

- `gleam run -m rally load-rpc`
- `gleam build --target erlang`
- `gleam build --target javascript`
- `TEMP=./tmp gleam test --target erlang`
- `node test/ws_result_smoke.mjs`
- `npm run test:browser`

## Summary of Changes

- Regenerated Rally load RPC glue so browser and SSR load dispatch comes from generated Proute/Rally wiring.
- Removed handwritten load route selectors and load result adapters from `src/public_boot.gleam` and `src/admin_boot.gleam`.
- Updated app roots to stop passing `select_load`; boot modules now keep only broadcast push handling.
- Validation: `gleam run -m rally load-rpc`; `gleam build --target erlang`; `gleam build --target javascript`; `TEMP=./tmp gleam test --target erlang`; `node test/boundary_guard_test.mjs`; `node test/ws_result_smoke.mjs`; `npm run test:browser`.
