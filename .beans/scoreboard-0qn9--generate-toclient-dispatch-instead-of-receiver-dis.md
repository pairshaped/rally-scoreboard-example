---
# scoreboard-0qn9
title: Generate ToClient dispatch instead of receiver dispatch
status: todo
type: task
priority: high
created_at: 2026-05-28T14:35:57Z
updated_at: 2026-05-28T14:35:57Z
parent: scoreboard-v94b
blocked_by:
    - scoreboard-h6f0
---

## What to build

Replace the generated client receiver dispatch path with generated to_client dispatch that calls active constructor-named client handlers. All server-originated ToClient values should flow through this dispatch path.

## Acceptance criteria

- [ ] Generated client modules are named generated/{mount}/to_client.gleam.
- [ ] generated/{mount}/receiver_dispatch.gleam is removed.
- [ ] client/{mount}/receivers.gleam is removed.
- [ ] Public and admin client roots call generated to_client dispatch for SSR hydration and WebSocket pushes.
- [ ] The dispatch fans out to every active page, layout, or ClientSharedState handler for a ToClient constructor.
- [ ] No new generated comments use receiver vocabulary.
- [ ] Generated snapshots are updated.
- [ ] Full test suite passes.

## Blocked by

- scoreboard-h6f0

## Notes for Claude

This should preserve the shared root ToClient graph. Do not introduce per-Mount ToClient graphs or topics. Cross-Mount delivery is still allowed when an active client handler handles the constructor.
