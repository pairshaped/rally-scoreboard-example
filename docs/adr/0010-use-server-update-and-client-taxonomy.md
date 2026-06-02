# Use Server Update And Client Taxonomy

Scoreboard uses app-owned server update boundaries and a browser-running client TEA app connected by generated ETF helper modules.

The server side should keep behavior explicit: decoded app messages reach server-owned code, and that code owns authorization checks, database work, domain decisions, and effects. That is not the same model as `../scoreboard-sc`. Scoreboard sends typed data over ETF to a real client app. It does not send VDOM diffs, and the browser owns normal Lustre rendering and hydration.

## Decision

Use this taxonomy consistently.

## Authored API Types

`ToServer` is the browser-to-server app message vocabulary. It is user-authored under `src/api/to_server.gleam`.

`ToClient` is the server-to-browser app data vocabulary. It is user-authored under `src/api/to_client.gleam`.

Domain types are user-authored wire-visible data types under `src/api/domain/**` or another `src/api/**` module. Domain types are not message roots by themselves.

All user-authored wire-visible constructors under `src/api/**` share one plain ETF constructor namespace. Module paths do not disambiguate constructor names.

## Generated API Types

Libero generates the result error types under `src/generated/api/result.gleam`:

```gleam
pub type ApiLoadError {
  ApiLoadError(message: String)
}

pub type ApiSaveError {
  ApiSaveError(field: Option(String), message: String)
}
```

These are generated protocol helper types, not user-authored domain types. User code must not define `ApiLoadError`, `ApiSaveError`, `api_load_error`, or `api_save_error` in `src/api/**`.

## Results

A load result is:

```gleam
Result(Nil, List(ApiLoadError))
```

A save result is:

```gleam
Result(Nil, List(ApiSaveError))
```

A result says whether the server accepted or rejected the operation. `Ok(Nil)` carries no data. `Error(errors)` carries protocol-oriented errors. Domain data still travels through `ToClient`.

Do not introduce custom operation-status wrapper types for this shape.

## Delivery

The browser sends a module name and a `ToServer` value to the server.

The server returns a load result or save result for the current request.

The server sends `ToClient` app data when there is data for the browser to apply. That app data may be sent for the current request or as a live push after the request path has finished.

Generated request and result helper surfaces do not expose a request id. The runtime treats results as app messages, not as correlated RPC promises.

## App Data

App data is state or event data the client can apply to its own model. App data uses `ToClient`.

Examples:

- `GamesLoaded`
- `GameLoaded`
- `AdminGamesLoaded`
- `GameUpdated`

Boot data is app data produced for the first page model. Hydration data is boot data embedded in the initial HTML so the client can start from the same loaded page state. Live push data is app data sent after the page is running.

## Server Update Boundary

The server update boundary is the app-owned server behavior flow:

```text
ToServer -> server update -> result + List(ToClient) + server effects
```

Server update code owns authorization checks, database work, and domain decisions. The WebSocket runtime owns transport decode, transport encode, socket writes, and live fanout.

Server effects are server-side I/O or runtime actions such as SQL writes, topic membership, and broadcast delivery. They do not belong in generated codec modules.

## Client TEA

Client TEA is the browser-running Lustre app flow:

```text
browser event -> client Message -> client update -> effects
ToClient -> client ToClient handler -> page model
result -> client result handling
```

Local page messages are browser-originated UI messages. They do not cross the wire and they do not mirror `ToClient` constructors.

Client `ToClient` handlers apply app data directly to page, layout, or shared client models. The client renders from typed data; it does not adopt server-owned VDOM patches.

## Comparison With Scoreboard SC

`../scoreboard-sc` uses Lustre server components. Its server component runtime owns the UI model and sends DOM or VDOM patch data to the browser. That makes each server page feel local and cohesive.

This project keeps server behavior explicit, but keeps a real client TEA app for rendering, navigation, and hydration. The server sends ETF app data and results, not patch instructions.

`scoreboard-sc` also uses page-local server page types. This project does not. Page-local wire types would complicate ETF decoding and the global plain-constructor namespace. Wire-visible app and domain types stay rooted under `src/api/**`.

## Consequences

The same names describe code, generated helpers, ADRs, and beans.

`ToClient` stays focused on app data instead of accumulating operation status constructors.

Server code can move toward clearer update/effect boundaries without turning Libero into a server-components transport.
