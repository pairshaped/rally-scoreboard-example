# Keep Dispatch Effect Agnostic

Scoreboard's server API dispatch maps decoded `ToServer` values to app-owned
handlers and returns a no-data ack plus any `ToClient` app-data values.

The dispatch layer should not own sockets, process groups, request framing,
response framing, or browser delivery. It should be usable from a WebSocket
handler, an SSR boot path, a test, or a future HTTP endpoint.

## Decision

`server/api.gleam` owns app dispatch:

```gleam
pub fn dispatch(
  db db: sqlight.Connection,
  message message: to_server.ToServer,
) -> List(to_client.ToClient)
```

Each `ToServer` constructor maps to one app handler. Handlers may read or write
SQLite, then return zero or more `ToClient` values.

The WebSocket runtime owns frame decode, response frame encode, socket writes,
and live fanout. Libero's generated modules own only ETF codec and frame helper
code.

Frame decode and encode live outside dispatch. The WebSocket runtime decodes one
generated request frame, calls dispatch, sends the no-data ack, and routes
any `ToClient` app-data values.

## Consequences

Handlers stay small and easy to test.

Transport code can change without rewriting app behavior.

The app can reuse the same `ToServer` handler flow for page boot, socket
requests, and operation acks.
