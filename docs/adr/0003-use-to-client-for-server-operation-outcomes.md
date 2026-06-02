# Use ToClient For Server App Data

`ToServer` is the browser-to-server command vocabulary. `ToClient` is the
server-to-browser app-data vocabulary.

Any public custom type named `ToServer` under `api` contributes command
messages. Any public custom type named `ToClient` under `api` contributes
app-data messages. Other public custom types under `api` are reusable
wire-visible domain types.

## Decision

Server app data is a `ToClient` value.

Load data, boot data, and live update data use `ToClient` constructors. For
example, `GamesLoaded` and `GameUpdated` are `ToClient` values.

No-data load and save results use Gleam's built-in `Result` directly:

```gleam
Result(Nil, List(ApiLoadError))
Result(Nil, List(ApiSaveError))
```

Libero generates the result error types:

```gleam
pub type ApiLoadError {
  ApiLoadError(message: String)
}

pub type ApiSaveError {
  ApiSaveError(field: Option(String), message: String)
}
```

Successful load and save results are `Ok(Nil)`. Load data and changed domain data
still travel as `ToClient` values.

Request and result helper surfaces do not expose a request id. The app treats results
as messages in the client and server update flow, not as correlated RPC promises.

Local page `Msg` types are for browser-originated page events such as clicks,
input changes, timers, subscriptions, and JavaScript callbacks. They do not
mirror `ToClient` constructors and they do not cross the wire.

`NotAsked`, `Loading`, and other async state markers belong in client models,
not in the API contract.

## Consequences

The wire protocol separates no-data load/save results from app data.

Client `ToClient` handlers only apply app data.

Operation success and failure can be handled without adding confirmation or
failure constructors to `ToClient`, and without adding user-authored result
wrapper types.
