---
# scoreboard-xcy9
title: Enforce client ToClient mini-update conventions
status: completed
type: task
priority: high
created_at: 2026-05-28T19:36:53Z
updated_at: 2026-05-28T19:53:33Z
parent: scoreboard-nwoq
blocked_by:
    - scoreboard-tdxl
    - scoreboard-fmsn
---

## What to build

Add structural tests and generated-code comments that lock in the client `ToClient` mini-update convention from the ADRs.

The tests should fail when generated dispatch or client page modules drift back to the old receiver-like shape where `ToClient` handlers return local page `Msg` values.

## Acceptance criteria

- [ ] Tests assert client `ToClient` handlers receive `model model: Model` as the first argument and constructor fields as labeled args.
- [ ] Tests assert client `ToClient` handlers return `#(Model, Effect(Msg))`, not local `Msg`.
- [ ] Tests assert generated `to_client` dispatch does not return `List(Msg)` for server-emitted events.
- [ ] Tests assert generated `to_client` dispatch stores returned page models and batches page effects.
- [ ] Tests assert local page `Msg` constructors do not mirror `ToClient` constructors only to enter `update`.
- [ ] Generated `to_client` module comments describe the mini-update handler convention and local `Msg` boundary.
- [ ] Shared, client, and server tests pass.

## Blocked by

- scoreboard-tdxl
- scoreboard-fmsn
