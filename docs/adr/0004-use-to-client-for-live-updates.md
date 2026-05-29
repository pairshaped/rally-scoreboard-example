# Use ToClient For Live Updates

The Generator Framework's live updates use `ToClient` values.

```gleam
pub type ToClient {
  GameCreated(game: GameSnapshot)
  GameUpdated(game: GameSnapshot)
}
```

Live broadcast constructors carry public-safe domain event payloads. `GameSnapshot` includes teams (with code, name, slug) so public and admin clients can derive whatever they need without receiving admin-only row shapes.

A server handler may emit one or more `ToClient` values. Those values use the same transport and client `to_client` dispatch path whether they came from the current client's command or another server-side update:

```text
ToClient -> generated to_client dispatch -> active client ToClient handlers -> page models
```

There are no separate live-update topic or payload types in the public API. A constructor-named client `ToClient` handler is the client-side interest signal. If multiple active client modules handle the same `ToClient` constructor, the Generator Framework fans the value out to all of them. If no active client handler handles the value, the configured no-handler policy applies.

Client `ToClient` handlers do not proxy server events into local page `Msg` values. They receive the page model and constructor fields, then return the updated page model plus any client effect. Local page `Msg` values are reserved for browser-originated events.

Wire-visible `ToClient` constructors participate in the shared API codec graph. Their constructor names must be unique plain ETF atoms, just like `ToServer` and domain constructors.
