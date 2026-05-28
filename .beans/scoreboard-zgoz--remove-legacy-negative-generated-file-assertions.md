---
# scoreboard-zgoz
title: Remove legacy negative generated-file assertions
status: todo
type: task
priority: low
created_at: 2026-05-28T15:36:51Z
updated_at: 2026-05-28T15:36:51Z
parent: scoreboard-v94b
blocked_by:
    - scoreboard-jw3x
    - scoreboard-74zk
---

## What to build

Remove old negative source-shape assertions that only prove legacy generated files do not exist. These were useful during migration, but after the page and ToClient conventions settle they become documentation of the old world.

## Acceptance criteria

- [ ] Remove negative tests for deleted legacy generated files such as receiver_dispatch.gleam.
- [ ] Remove similar negative assertions for old page_dispatch/rpc_dispatch/generated layout paths when they no longer carry useful design signal.
- [ ] Keep positive assertions that document the desired generated files and runtime paths.
- [ ] Update snapshots only if test output changes.
- [ ] Full test suite passes.
- [ ] beans check passes.

## Blocked by

- scoreboard-jw3x
- scoreboard-74zk

## Notes for Claude

Do this after the active convention cleanup beans. The goal is to stop tests from teaching obsolete names while keeping useful guardrails for the intended generated shape.
