---
# scoreboard-h6f0
title: Move ToClient handlers into mirrored client pages
status: completed
type: task
priority: high
created_at: 2026-05-28T14:35:46Z
updated_at: 2026-05-28T14:58:20Z
parent: scoreboard-v94b
blocked_by:
    - scoreboard-vv5p
---

## What to build

Create client page modules that mirror the shared and server page paths, then move page-owned ToClient handling out of shared pages and into those client page modules. Shared pages should keep target-neutral model, view, and pure helpers only.

## Acceptance criteria

- [x] Client page modules exist for public games, public game detail, public standings, public team, and admin games.
- [x] Shared page modules no longer import shared/api/to_client.
- [x] Shared page modules no longer expose receive(event: ToClient).
- [x] Client page handlers use constructor-derived snake_case names such as games_loaded, game_score_updated, standings_loaded, team_loaded, admin_games_loaded, and admin_error.
- [x] Client page handlers receive constructor fields as named args rather than the whole ToClient value.
- [x] Client roots still update the same visible page state after SSR hydration and live ToClient pushes.
- [x] Full test suite passes.

## Summary of Changes

Created 5 client page modules mirroring route paths:

- `client/src/client/public/pages/games.gleam`
- `client/src/client/public/pages/games/id_.gleam`
- `client/src/client/public/pages/standings.gleam`
- `client/src/client/public/pages/teams/slug_.gleam`
- `client/src/client/admin/pages/games.gleam`

Each client page module owns its `Msg` type and constructor-named ToClient handlers (e.g. `games_loaded`, `game_score_updated`, `standings_loaded`, `team_loaded`, `admin_games_loaded`, `admin_error`). Handlers receive constructor fields as named args.

Removed `Msg` types, `receive` functions, and `shared/api/to_client` imports from all 5 shared page modules. Shared pages keep target-neutral model, view, and pure helpers only.

Rewrote `client/public/receivers.gleam` and `client/admin/receivers.gleam` to dispatch ToClient constructors to the new client page handlers. Updated both client roots to import Msg types from client pages while keeping view imports from shared pages. Removed receive/Msg tests from shared test files (those tests now belong in the client domain).

Full test suite: 34 shared, 4 client, 82 server (all passing).
