---
# scoreboard-nwoq
title: Apply ToClient handlers as page mini-updates
status: todo
type: epic
priority: high
created_at: 2026-05-28T19:18:35Z
updated_at: 2026-05-28T19:36:18Z
parent: scoreboard-v94b
---

Implement the ADR target for client ToClient handling.

Target shape:

- Local page `Msg` values are only for browser-originated events: inputs, clicks, timers, subscriptions, and JS FFI callbacks.
- Server-emitted `ToClient` values are not mirrored into local page `Msg` constructors.
- Client page `ToClient` handlers take the page `Model` plus constructor fields and return `#(Model, Effect(Msg))`.
- Generated Mount `to_client` dispatch owns the page-model bundle, applies server-emitted `ToClient` values to active page handlers, stores returned page models, and batches page effects.
- Root clients receive raw `ToClient` values, store the generated page-model bundle, and delegate server event handling to generated `to_client` dispatch.

Implementation should proceed through child beans in dependency order.
