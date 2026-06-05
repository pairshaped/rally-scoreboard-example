---
# scoreboard-unified-n4vg
title: Remove root browser navigation routing work
status: todo
type: task
priority: high
tags:
    - rally
    - routing
    - browser
created_at: 2026-06-05T18:00:00Z
updated_at: 2026-06-05T18:00:00Z
parent: scoreboard-unified-r0ut
---

## What to build

Remove route matching and route construction from authored browser root modules, especially `src/public_app.gleam` and `src/admin_app.gleam`.

The app roots should own shell state, dark mode, and browser lifecycle callbacks. They should not map page-local navigation messages to generated route values, parse route params, or decide how a route loads a page.

## Current routing work to remove

- `public_app.page_navigation` matches generated `pages.Message` wrappers and page-local navigation messages.
- `public_app.page_navigation` builds `routes.TeamsSlug` and `routes.GamesId`, including `int.to_string` for route params.
- Public and admin app roots call `routes.parse_path` for startup and browser path changes.
- Public and admin app roots call `routes.route_to_path` during navigation.
- Public and admin app roots pass `public_boot.load_route` and `admin_boot.load_route` as manual route-aware selectors.

## Acceptance criteria

- Public/admin app roots do not construct generated route values from page messages.
- Public/admin app roots do not stringify route params.
- Browser path parsing and route-to-path conversion happen in generated Proute/Rally glue.
- Page modules expose navigation intent in a page-local way, or generated glue consumes page-owned navigation hooks without requiring root route dispatch.
- Existing navigation behavior remains unchanged.

## Validation

- `gleam build --target javascript`
- `npm run test:browser`
- Browser smoke should cover team links, game detail links, shell navigation, and browser back/forward path changes.
