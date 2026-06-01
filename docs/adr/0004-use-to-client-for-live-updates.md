# Use ToClient For Live Updates

The generator's live updates use `ToClient` values.

```gleam
pub type ToClient {
  GameUpdated(game: GameSnapshot)
}
```

Live broadcast constructors carry public-safe domain event payloads. `GameSnapshot` includes teams (with code, name, slug) so public and admin clients can derive whatever they need without receiving admin-only row shapes.

A server handler may emit one or more `ToClient` values. Those values use the
same transport and client reducer path whether they came from the current
client's command or another server-side update:

```text
ToClient -> client/to_client reducer -> page model
```

There are no separate live-update topic or payload types in the public API. The
app runtime decides which connected clients receive each pushed `ToClient`
value. The current runtime uses one app-level process group and lets client
reducers ignore values that are irrelevant to their active page.

Client `ToClient` handlers do not proxy server events into local page `Msg`
values. In this app, `client/to_client.gleam` applies decoded `ToClient` values
to the active page model and returns any client effect. Local page `Msg` values
are reserved for browser-originated events.

Wire-visible `ToClient` constructors participate in the shared API codec graph. Their constructor names must be unique plain ETF atoms, just like `ToServer` and domain constructors.
