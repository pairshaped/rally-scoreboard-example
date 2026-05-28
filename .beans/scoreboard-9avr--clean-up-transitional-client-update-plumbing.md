---
# scoreboard-9avr
title: Clean up transitional client update plumbing
status: completed
type: task
priority: normal
created_at: 2026-05-28T19:37:02Z
updated_at: 2026-05-28T19:54:59Z
parent: scoreboard-nwoq
blocked_by:
    - scoreboard-xcy9
---

## What to build

Remove leftover names, comments, tests, and root/client plumbing from the transitional receiver-to-page-message architecture after the mini-update convention is implemented.

This is cleanup after the behavior is working, not a place to introduce a new design.

## Acceptance criteria

- [ ] No active code or comments describe server-emitted `ToClient` values as being converted into local page `Msg` values.
- [ ] Root clients do not contain duplicated server-event update logic that belongs in generated `to_client` dispatch or client page handlers.
- [ ] Page modules do not keep helper names that imply receiver-style proxying for server events.
- [ ] Birdie snapshots and structural tests reflect the final architecture, not the transitional state.
- [ ] Shared, client, and server tests pass.
- [ ] `beans check` passes.

## Blocked by

- scoreboard-xcy9
