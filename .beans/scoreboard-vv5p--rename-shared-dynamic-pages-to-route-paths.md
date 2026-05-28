---
# scoreboard-vv5p
title: Rename shared dynamic pages to route paths
status: completed
type: task
priority: high
created_at: 2026-05-28T14:35:35Z
updated_at: 2026-05-28T14:44:28Z
parent: scoreboard-v94b
---

## What to build

Make shared page modules use the same Mount-relative route paths as the server pages for dynamic public routes. This removes view-oriented module names from the routing shape.

## Acceptance criteria

- [x] shared public game detail page moves from game_detail to games/id_.
- [x] shared public team page moves from team to teams/slug_.
- [x] All imports in client roots, generated SSR handlers, tests, and snapshots use the route-shaped module names.
- [x] No alias modules are left behind just to preserve old names.
- [x] Full test suite passes.

## Summary of Changes

Moved shared public page modules to route-shaped paths matching the server page convention:

- `shared/src/shared/public/pages/game_detail.gleam` -> `shared/src/shared/public/pages/games/id_.gleam`
- `shared/src/shared/public/pages/team.gleam` -> `shared/src/shared/public/pages/teams/slug_.gleam`

Updated imports in 6 files: generated SSR handler, public client root, receivers, client test, and both shared view tests. Updated Birdie snapshot for `src_generated_public_ssr_handler_gleam`. No alias modules left behind.

Full test suite: 55 shared, 4 client, 82 server (all passing).
