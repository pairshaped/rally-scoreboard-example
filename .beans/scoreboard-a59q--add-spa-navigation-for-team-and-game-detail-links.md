---
# scoreboard-a59q
title: Add SPA navigation for team and game detail links
status: completed
type: task
priority: normal
tags:
    - routing
    - javascript-target
    - client-shared-state
created_at: 2026-06-01T22:14:26Z
updated_at: 2026-06-01T23:07:33Z
---

## Problem

The unified app renders team and game detail links, but clicking them does not currently navigate inside the running Lustre app.

The likely root is that page-level navigation messages such as NavigateTeam and NavigateGame are emitted by page views, but the mount-level public app does not yet translate those page messages into route changes, browser history updates, or route reloads.

Do not rush straight to modem. This is a useful test of the JavaScript-target side of the universal source approach, but it should be designed deliberately.

## Direction

Investigate the smallest navigation layer for the unified JavaScript target:

- keep route parsing and page loading in generated Proute modules
- handle page navigation messages at the public app shell boundary
- update browser history and reload the generated page model
- preserve server-backed load effects for the destination page
- decide whether modem is worth adding now or whether a tiny target-specific browser boundary is enough

This should stay separate from dark-mode/device preference state. Both belong at the app shell level, but navigation has different semantics and should not be tangled into the preference-cookie tracer bullet.

## Current code references

- src/public_app.gleam owns the public mount model and wraps generated pages.
- src/public/pages/games.gleam emits NavigateTeam and NavigateGame.
- src/public/pages/games/id_.gleam emits NavigateTeam.
- src/public/pages/teams/slug_.gleam emits NavigateTeam and NavigateGame.
- src/public/pages/standings.gleam emits NavigateTeam.
- src/generated/proute/public/routes.gleam already knows how to parse and build route paths.

## Acceptance criteria

- Clicking team links navigates to /teams/:slug without a full page reload.
- Clicking game detail links navigates to /games/:id without a full page reload.
- Back/forward navigation keeps the rendered page and browser URL in sync.
- Destination page load effects still run and receive their ToClient responses.
- The implementation uses @target(javascript) only at real browser boundaries.
- If modem is introduced, document why it earns the dependency.


## Completed notes

Implemented public SPA navigation for team and game detail links at the mount boundary. Page-level navigation messages now map to generated routes, update browser history, reload the generated page model, and preserve destination load effects. Browser back/forward dispatches the current path back into the Lustre app without a full document reload.

Validation run before completion:

- `gleam format src`
- `gleam check`
- `gleam build --target javascript`
- `gleam build --target erlang`
- `gleam run -m glinter`
- `beans check`
- browser smoke test covering `/games`, game detail navigation, team navigation, and back/forward state sync
