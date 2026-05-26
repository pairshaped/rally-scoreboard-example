# Use Server Runtime State For Live Connections

The Generator Framework uses its own server runtime state to manage live client connections. The runtime tracks small live facts such as connection identity, session/context, current page/route, active receiver interests, and outgoing `ToClient` delivery.

This state is framework runtime state. App-owned live server state belongs in the Mount backend model. Page models stay on the client. Durable app data stays in SQLite or another database/cache. Large event snapshots should not be stored per connection.

The live update flow is:

1. A client connects or navigates.
2. The Generator Framework knows the connection's current page and route.
3. The Generator Framework knows the active receivers for that client root.
4. Server code emits one or more `ToClient` values.
5. The Generator Framework delivers each `ToClient` value to the intended client roots.
6. Generated client receiver dispatch routes the value to every active receiver that handles its constructor.

Receiver handlers are the client-side interest signal. A page, layout, or shared-state module that handles `GameScoreUpdated` is interested in that message whenever it is active. The Generator Framework does not require a separate live-update topic declaration for that interest.

Every server-originated value shares the same receive path after transport decode:

```text
ToClient -> active receivers -> local Msg values -> update
```

App-wide string notices use the Generator Framework's built-in layout/client-shell lane. Rich app-wide payloads use `ToClient` values.

This fits BEAM well: many mostly idle connection processes with small state, supervised brokers, and message-passing fanout. It also supports embedded widgets such as the Curling I/O results widget: initial snapshots can still use CDN-cached reads, while live score changes can be pushed as compact deltas.

The Generator Framework can grow server runtime state over time for presence, current route tracking, receiver counts, fanout stats, slow-consumer stats, and admin introspection. App-owned per-connection server app state belongs in `backend.Model`. Durable app data stays in the database or cache.
