---
# scoreboard-0qn9
title: Generate ToClient dispatch instead of receiver dispatch
status: completed
type: task
priority: high
created_at: 2026-05-28T14:35:57Z
updated_at: 2026-05-28T15:17:35Z
parent: scoreboard-v94b
blocked_by:
    - scoreboard-h6f0
---

## What to build

Replace the generated client receiver dispatch path with generated to_client dispatch that calls active constructor-named client handlers. All server-originated ToClient values should flow through this dispatch path.

## Acceptance criteria

- [x] Generated client modules are named generated/{mount}/to_client.gleam.
- [x] generated/{mount}/receiver_dispatch.gleam is removed.
- [x] client/{mount}/receivers.gleam is removed.
- [x] Public and admin client roots call generated to_client dispatch for SSR hydration and WebSocket pushes.
- [x] The dispatch fans out to every active page, layout, or ClientSharedState handler for a ToClient constructor.
- [x] No new generated comments use receiver vocabulary.
- [x] Generated snapshots are updated.
- [x] Full test suite passes.

## Summary of Changes

Created generated `to_client.gleam` modules that replace both `receiver_dispatch.gleam` and `receivers.gleam`:

- `client/src/generated/public/to_client.gleam` — exhaustive ToClient dispatch to public client page handlers
- `client/src/generated/admin/to_client.gleam` — exhaustive ToClient dispatch to admin client page handlers

Deleted 4 files: `generated/public/receiver_dispatch.gleam`, `generated/admin/receiver_dispatch.gleam`, `client/public/receivers.gleam`, `client/admin/receivers.gleam`.

Updated both client roots to call `public_to_client_dispatch.to_client(event)` / `admin_to_client_dispatch.to_client(event)` instead of the old receiver dispatch. Updated the client test and the mount_clients contract test. Updated Birdie snapshots: added 2 new to_client snapshots, removed 2 old receiver_dispatch snapshots.

Full test suite: 34 shared, 4 client, 82 server (all passing).
