# Use ToClient For Server Emissions

`ToServer` is the browser-to-server command vocabulary. `ToClient` is the
server-to-browser result, boot data, and event vocabulary.

Any public custom type named `ToServer` under `api` contributes command
messages. Any public custom type named `ToClient` under `api` contributes
server-emitted messages. Other public custom types under `api` are reusable
wire-visible domain types.

## Decision

Every app-visible server emission is a `ToClient` value.

Operation result constructors carry the data the client needs to update local
state. Operations that only need confirmation carry an app-defined confirmation
constructor such as `ScoreUpdateSaved` or `ResultSaved`. Failure outcomes use
app-defined `ToClient` constructors such as `AdminError`.

Request frames may produce response frames. Response frames carry a request id
for transport correlation, but the app payload is still a `ToClient` value.
Live pushes also carry `ToClient` values. After decode, clients apply both
response and push messages through the same reducer path.

Local page `Msg` types are for browser-originated page events such as clicks,
input changes, timers, subscriptions, and JavaScript callbacks. They do not
mirror `ToClient` constructors and they do not cross the wire.

`NotAsked`, `Loading`, and other async state markers belong in client models,
not in the API contract.

## Consequences

The wire protocol has one server emission vocabulary.

Operation responses and live events reuse the same page update code.

Transport correlation stays outside the API domain types.
