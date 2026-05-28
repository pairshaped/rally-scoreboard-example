---
# scoreboard-h6f0
title: Move ToClient handlers into mirrored client pages
status: todo
type: task
priority: high
created_at: 2026-05-28T14:35:46Z
updated_at: 2026-05-28T14:35:46Z
parent: scoreboard-v94b
blocked_by:
    - scoreboard-vv5p
---

## What to build

Create client page modules that mirror the shared and server page paths, then move page-owned ToClient handling out of shared pages and into those client page modules. Shared pages should keep target-neutral model, view, and pure helpers only.

## Acceptance criteria

- [ ] Client page modules exist for public games, public game detail, public standings, public team, and admin games.
- [ ] Shared page modules no longer import shared/api/to_client.
- [ ] Shared page modules no longer expose receive(event: ToClient).
- [ ] Client page handlers use constructor-derived snake_case names such as games_loaded, game_score_updated, standings_loaded, team_loaded, admin_games_loaded, and admin_error.
- [ ] Client page handlers receive constructor fields as named args rather than the whole ToClient value.
- [ ] Client roots still update the same visible page state after SSR hydration and live ToClient pushes.
- [ ] Full test suite passes.

## Blocked by

- scoreboard-vv5p

## Notes for Claude

Do not keep client/public/receivers.gleam or client/admin/receivers.gleam as the long-term abstraction. They can be temporary stepping stones during the change, but the final ownership should be client page modules.
