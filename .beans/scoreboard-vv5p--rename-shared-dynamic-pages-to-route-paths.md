---
# scoreboard-vv5p
title: Rename shared dynamic pages to route paths
status: todo
type: task
priority: high
created_at: 2026-05-28T14:35:35Z
updated_at: 2026-05-28T14:35:35Z
parent: scoreboard-v94b
---

## What to build

Make shared page modules use the same Mount-relative route paths as the server pages for dynamic public routes. This removes view-oriented module names from the routing shape.

## Acceptance criteria

- [ ] shared public game detail page moves from game_detail to games/id_.
- [ ] shared public team page moves from team to teams/slug_.
- [ ] All imports in client roots, generated SSR handlers, tests, and snapshots use the route-shaped module names.
- [ ] No alias modules are left behind just to preserve old names.
- [ ] Full test suite passes.

## Blocked by

None - can start immediately.

## Notes for Claude

Server pages already use server/public/pages/games/id_.gleam and server/public/pages/teams/slug_.gleam. Match that shape in shared. This task is only about shared route-path alignment; do not move ToClient handling yet unless it is needed for compilation.
