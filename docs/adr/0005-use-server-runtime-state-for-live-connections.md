# Use App-Owned Runtime State For Live Connections

Scoreboard owns its WebSocket runtime in app source. Libero generates ETF codec
and frame helper modules, but it does not own connection state, topic routing,
or server handler dispatch.

## Decision

The Erlang runtime uses Mist for the HTTP and WebSocket server.

Each WebSocket connection keeps a small `server/ws.State` with the shared
database connection. Incoming binary frames are decoded by
`generated/api/server`, dispatched through `server/api`, and encoded back as
generated response frames.

Live fanout uses an Erlang `pg` group through `server/topics.gleam` and
`server_topics_ffi.erl`. Connected sockets join the app group. When a server
operation produces a public live event such as `GameUpdated`, the WebSocket
handler broadcasts a generated push frame to the group.

The sender receives normal response frames for the request it sent. Other
connected clients receive push frames. Both carry `ToClient` payloads.

The browser runtime is app-owned in `client/api.gleam` and
`client/api_ffi.mjs`. It opens a WebSocket, queues outbound generated request
frames until the socket is open, reconnects after close, and delivers inbound
frames to the app shell.

There is no generated per-page socket handler, page-local server component, or
generated JavaScript embedding lane. Browser-only code lives in app-owned
JavaScript FFI or JavaScript-targeted Gleam modules.

## Consequences

The runtime is explicit and easy to inspect in this app.

Libero remains a codec and frame generator instead of becoming the web
framework.

Live delivery is coarse today: connected clients join the app group and page
reducers ignore irrelevant `ToClient` values. Finer interest tracking can be a
future app or framework decision.
