---
# scoreboard-unified-qf1q
title: Migrate remaining public loads to page-local contracts
status: todo
type: feature
priority: normal
tags:
    - rally
    - chase
created_at: 2026-06-04T03:38:31Z
updated_at: 2026-06-04T03:38:31Z
parent: scoreboard-unified-wm8p
blocked_by:
    - scoreboard-unified-adc2
---

## What to build

Move the remaining public page load paths to page-local server handlers and page-local wire payloads: game detail, standings, team detail, and home-as-games if it remains an alias.

Each page should own its own domain model, even when the shapes look similar. A list page, detail page, and form/workflow page should be free to evolve independently.

## Plan outline

- Apply the generated page-local load pattern from the public games slice to each public page.
- Keep authored SQL beside the owning page/workflow in local `sql/` directories.
- Keep generated SQL modules under generated SQL output.
- Remove root API/domain references from each migrated load path.
- Keep route-first, decode-second behavior so two pages can define same-named local types.
- Update SSR and browser smoke coverage as each route moves.

## Acceptance criteria

- [ ] Game detail loads through a page-local contract and does not expose stale root `GameDetail` shapes.
- [ ] Standings loads through a page-local contract and owns its own game/standing model shapes.
- [ ] Team detail loads through a page-local contract and owns its own team/game shapes.
- [ ] Public browser navigation receives one correlated load result frame per page load.
- [ ] No migrated public load path imports root API/domain models.

## Blocked by

- Rally load RPC generation for page-local contracts.
