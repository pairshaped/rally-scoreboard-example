# Use ToClient For Live Updates

The Generator Framework's live updates use `ToClient` values.

```gleam
pub type ToClient {
  GameScoreUpdated(update: GameScoreUpdate)
  StandingsUpdated(rows: List(StandingRow))
}
```

A server handler may emit one or more `ToClient` values. Those values use the same transport and receiver path whether they came from the current client's command or another server-side update:

```text
ToClient -> active receivers -> local Msg values -> update
```

There are no separate live-update topic or payload types in the public API. A receiver handler is the client-side interest signal. If multiple active receivers handle the same `ToClient` constructor, the Generator Framework fans the value out to all of them. If no active receiver handles the value, the configured no-receiver policy applies.

Wire-visible `ToClient` constructors participate in the shared API codec graph. Their constructor names must be unique plain ETF atoms, just like `ToServer` and domain constructors.
