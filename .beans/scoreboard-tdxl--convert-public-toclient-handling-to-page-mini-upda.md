---
# scoreboard-tdxl
title: Convert public ToClient handling to page mini-updates
status: completed
type: task
priority: high
created_at: 2026-05-28T19:36:34Z
updated_at: 2026-05-28T19:48:06Z
parent: scoreboard-nwoq
---

## What to build

Convert the public Mount so server-emitted `ToClient` values update public page models directly through constructor-named page handlers.

The public root should receive raw `ToClient` values, store a generated public page-model bundle, and delegate server events to generated public `to_client` dispatch. Public page modules should keep `Model`, `init`, and local `update`, but remove local `Msg` constructors that only mirror `ToClient` constructors.

## Acceptance criteria

- [ ] Public page `ToClient` handlers take the page `Model` plus constructor fields and return `#(Model, Effect(Msg))`.
- [ ] Public local page `Msg` types do not contain protocol-shaped constructors such as loaded, updated, or failed variants that only mirror `ToClient`.
- [ ] Generated public `to_client` dispatch owns a public page-model bundle, applies `ToClient` values to active public page handlers, stores returned page models, and batches page effects.
- [ ] `scoreboard_public_client.gleam` receives raw shared `ToClient` values and delegates server-event handling to generated public `to_client` dispatch.
- [ ] SSR hydration still seeds public page models through the same generated public `to_client` dispatch path.
- [ ] Public fanout still applies `GameScoreUpdated` and `GamesLoadFailed` to every active/interested public page.
- [ ] Shared, client, and server tests pass.

## Blocked by

None - can start immediately.
