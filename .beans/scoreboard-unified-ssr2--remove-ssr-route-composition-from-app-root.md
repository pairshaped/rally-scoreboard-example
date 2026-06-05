---
# scoreboard-unified-ssr2
title: Remove SSR route composition from app root
status: todo
type: task
priority: normal
tags:
    - rally
    - routing
    - ssr
created_at: 2026-06-05T18:00:00Z
updated_at: 2026-06-05T18:00:00Z
parent: scoreboard-unified-r0ut
---

## What to build

Reduce `src/app_ssr.gleam` to app-owned SSR concerns: request/session identity, auth context, shell rendering, and data dependencies. Generated Rally/Proute glue should own path parsing, route-to-path normalization, page boot/load dispatch, hydration payload selection, and generated page view dispatch.

## Current routing work to remove

- `app_ssr.public_render` parses public paths into generated routes.
- `app_ssr.admin_render` parses admin paths into generated routes.
- `app_ssr` calls `route_to_path` to compute shell `current_path`.
- `app_ssr` imports generated page modules to render page content.
- `app_ssr` passes route-aware boot selectors into generated SSR helpers.

## Acceptance criteria

- `app_ssr.gleam` does not import generated route modules.
- Route parsing and route-to-path normalization happen in generated Proute/Rally glue.
- App SSR code still owns shell choice and identity/auth context.
- Generated glue can return the rendered page element or enough page output for the app shell without making app code match routes.
- Public and admin SSR behavior remains unchanged.

## Validation

- `gleam build --target erlang`
- `TEMP=./tmp gleam test --target erlang`
- Browser smoke or SSR snapshot coverage should verify public/admin initial documents and hydration payloads.
