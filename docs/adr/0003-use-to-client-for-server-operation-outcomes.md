# Use ToClient For Server Emissions

The Generator Framework's server emissions are delivered as `ToClient` values. `ToServer` is the client-to-server command vocabulary. `ToClient` is the server-to-client result and event vocabulary.

Any public custom type named `ToServer` under `shared/api` contributes command messages. Any public custom type named `ToClient` under `shared/api` contributes server-emitted messages. Other public custom types under `shared/api` are domain types.

Operation result constructors carry the data the client needs to update local state. Operations that only need confirmation carry `Nil` or an app-defined empty result. `NotAsked`, `Loading`, and other async state markers belong in client models.

Client-originated commands enter the server through `backend.Msg.FromClient(ToServer, RequestContext)`. The backend update may emit one or more `ToClient` values itself, or delegate to generated dispatch so a colocated server handler can emit values.

Pages map `ToClient` constructors into local `Msg` values through generated receiver dispatch or explicit receiver functions. Local page `Msg` types remain client state-machine inputs for UI events, browser effects, and page update logic. They do not cross the wire.

`ToServer` uses a command lane, not the RPC response lane. The client sends the command and does not register a response callback or wait for a transport acknowledgement. If the user needs to see success, failure, or resulting state, the server emits a `ToClient` constructor. Rare true fire-and-forget commands emit no app-visible value.
