# Default To Root API Contracts

The generator's wire contracts live under `api`.

Pages own local UI state and rendering. Server handlers own server behavior. Generated modules own codecs and transport glue. The `api` tree owns every type that crosses the wire.

## Decision

Only public user-authored app and domain types under `src/api/**` are wire-visible. Libero-generated protocol helper types live under `src/generated/api/**`.

The root API layout is:

```text
src/api/to_server.gleam
src/api/to_client.gleam
src/api/domain/**/*.gleam
src/api/**/*.gleam
```

The preferred shared API shape is:

```text
src/api/to_server.gleam
src/api/to_client.gleam
src/api/domain/game.gleam
src/api/domain/user.gleam
src/api/domain/**/*.gleam
```

Any user-authored type outside `src/api/**` is not a wire type. That includes
page models, page messages, route types, SQL row types, handler-local types,
view helper types, generated route types, runtime helper types, and database
result types.

## Root Message Types

Any public custom type named `ToServer` under `api` contributes browser-to-server command constructors. Constructor fields are the command payload.

```gleam
pub type ToServer {
  LoadGames
  UpdateScore(game_id: Int, home_score: Int, away_score: Int, period: String)
}
```

Any public custom type named `ToClient` under `api` contributes server-to-browser app-data constructors. Constructor fields are the delivered payload.

```gleam
pub type ToClient {
  GamesLoaded(games: List(game.PublicGameSummary))
  GameUpdated(game: game.GameSnapshot)
}
```

Other public custom types under `api` are reusable wire-visible domain shapes. They do not define one wrapper type per message just to make handlers receive a message-shaped value. The `ToServer` and `ToClient` unions are the message-shaped values.

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

Do not add custom operation-status wrapper types or app-authored `ApiLoadError` or `ApiSaveError` types for this shape. The error types are generated.

The generator uses client/server language for transport messages. `ToServer` and `ToClient` match the generator's package and runtime vocabulary.

## API Module Structure

Module structure under `api` is for code organization and JavaScript packaging. It does not create wire identity.

Public/admin Mount boundaries are expressed by user-owned app code and generated Mount modules, not by `api/public` or `api/admin` protocol roots.

Apps may split the shared API into additional modules for readability or packaging, but those modules are still one global wire graph. Any constructor that crosses the wire needs a unique plain ETF atom in the whole shared API graph.

Do not organize the API under:

```text
src/api/public/**
src/api/admin/**
```

Mount directories are fine for page and view modules because pages do not cross the wire.

## Wire Graph

The generator builds one shared API codec graph:

```text
src/api/**/*.gleam
```

Client and server code may import subsets of `api` for packaging, but those subsets do not weaken the global wire-name rule. Moving a type to another module or directory does not fix a wire collision. Renaming the constructor does.

The generator validates constructor names within the shared API graph. Duplicate plain ETF constructor names fail generation before codegen.

The check includes:

- `ToServer` constructors
- `ToClient` constructors
- domain constructors
- any other public wire-visible custom type constructor under `api`

The check does not use module paths, type names, transport direction, arity, namespace prefixes, hashes, or generated identities to disambiguate values.

Diagnostics for codec graph collisions are part of the contract. The generator names the duplicate constructor, the plain ETF atom, every file/type involved, and the expected fix.

```text
Duplicate ETF constructor `User` in the shared API codec graph.

Plain ETF uses constructor atoms without module or type identity, so the generator cannot
safely decode both of these values:

- api/domain/user.gleam
  User.User(id: Int)

- api/domain/admin_user.gleam
  AdminUser.User(id: Int)

Rename one constructor so every wire-visible constructor in api has
a unique plain ETF atom.
```

## Page Boundaries

Pages own local UI concerns:

```text
Model
Message for browser-originated events
form state
view helpers
browser-only UI data
client effects and JavaScript callbacks
```

Page modules may import `api` domain and protocol types. They do not define wire-visible `ToServer`, `ToClient`, or wire domain types.

Local page messages do not cross the wire. They are reserved for browser-originated page events such as clicks, input changes, timers, subscriptions, and JavaScript callbacks.

Server app data crosses the wire as `ToClient` values. Client `ToClient` handlers apply those values directly to page models. They do not mirror `ToClient` constructors into local page messages.

Browser-originated commands cross the wire as `ToServer` values. Libero's
generated API modules encode and decode the ETF frames. App-owned browser and
server transport modules move those frames over WebSocket and dispatch decoded
commands.

## Page Boot Requests

Page boot requests are the first-render data convention.

Shared page modules declare normal first-render server requests for a route:

```gleam
/// First-render server requests for this route.
///
/// Generated SSR executes these locally and embeds the returned ToClient
/// values for hydration. Generated client init sends these over WebSocket
/// only when hydration has not already populated the page model.
pub fn init_requests() -> List(to_server.ToServer) {
  [to_server.LoadGames]
}
```

`init_requests` is shared boot wiring for the route. It takes no page model, `RequestContext`, `ServerContext`, or `ClientSharedState`. It does not decide whether data is already present and it does not load data itself.

SSR execution may run the route's `init_requests`, map each `ToServer` value to
its server handler, and embed the returned `ToClient` values as page-data
hydration flags.

Client init sends `init_requests` over the app-owned API transport path when
hydration has not already populated the page model.

Static pages can omit `init_requests`.

## Server Handlers

Each `ToServer` constructor has exactly one server handler in the app dispatch
module.

The default handler convention maps a constructor to a snake-case function:

```text
LoadGames   -> load_games
UpdateScore -> update_score
MarkFinal   -> mark_final
```

This rule includes page-data load commands. `ToServer.LoadGames` maps to `load_games`; it does not map to page `init`.

Handlers receive constructor fields, plus any app-owned context they need. The
current app dispatches from the whole decoded `ToServer` value and delegates to
constructor-specific private handlers.

Page-data handlers return a load result plus the `ToClient` values that populate
the page:

```gleam
fn load_games(db: sqlight.Connection) -> DispatchReply {
  panic as "implemented by the app"
}
```

Operation handlers return a save result plus zero or more `ToClient` values so the current client and other active clients can update through the same app-data path.

Server-only handlers and imports carry Erlang target annotations in the unified source tree.

## Client ToClient Handlers

`ToClient` is the server app-data vocabulary. Pages and shared client state
handle `ToClient` values through app-owned reducer modules.

A client `ToClient` handler is a mini-update over the page model. Its function
name is the snake-case form of the `ToClient` constructor name:

```gleam
pub fn game_updated(
  model model: Model,
  game game: game.GameSnapshot,
) -> #(Model, Effect(Message)) {
  panic as "implemented by the app"
}
```

Handlers receive the page model as the first argument, then constructor fields
as named arguments.

Client `ToClient` handlers do not proxy server events into local page messages.
Local page messages are for browser-originated events.

## Runtime Taxonomy

ADR 0010 is the canonical taxonomy record. Use these terms consistently:

- `AuthenticationContext`: shared identity facts loaded from the browser session. It answers who the session represents.
- `RequestContext`: per-request or per-socket facts when a runtime needs them.
  It can carry route params, query params, session facts, and authenticated user
  facts.
- `ServerContext`: server-side resources such as DB handles, config, clocks,
  service clients, and logging.
- `ClientSharedState`: per-Mount browser state shared by the Mount shell, layouts, and pages.
- SSR `ToClient` page data: boot-time `ToClient` app data produced
  by executing the route's boot requests.
- page `Model`: local UI state for a page or root client app.
- live connection state: app-owned WebSocket state for one browser connection.
- `ToServer`: browser-to-server app message vocabulary.
- `ToClient`: server-to-browser app data vocabulary.
- load result: `Result(Nil, List(ApiLoadError))`.
- save result: `Result(Nil, List(ApiSaveError))`.

`ClientSharedState` and SSR `ToClient` page data are separate boot payloads. They must use separate runtime storage names so one cannot overwrite the other.

## Transport

The transport lane selects the payload shape:

```text
ToServer
ToClient
Result(Nil, List(ApiLoadError))
Result(Nil, List(ApiSaveError))
```

The root type drives top-down encoding and decoding. The generator does not infer payload identity by trying every known type. ETF carries runtime values. The generated codec graph supplies the root type information needed by the JavaScript and BEAM bridge.

Type aliases are transparent on the wire, as they are in Gleam. Domain identities that need runtime distinction use wrapper custom types.

`ToServer` frames are app messages. Server operation status travels as a load
result or a save result. Server app data travels as `ToClient`.

`ToClient` values are app data. They may be delivered to any active client handler in any Mount that handles the constructor.

## Rules

1. User-authored wire-visible app and domain types live under `src/api/**`.
2. Generated protocol helper types live under `src/generated/api/**`.
3. Other user-authored types outside `src/api/**` do not cross the wire.
4. Public custom types named `ToServer` under `api` define command constructors.
5. Public custom types named `ToClient` under `api` define app-data constructors.
6. Other public custom types under `api` are domain types.
7. Load and save results use generated Libero result error types and Gleam `Result`.
8. Live updates use `ToClient`.
9. Codec generation validates the selected `api` graph.
10. Module paths and directories under `api` are code organization only.
11. Duplicate plain ETF constructor names inside the shared API graph are generation errors.
12. Every `ToServer` constructor has exactly one server handler in the app.
13. `ToServer` constructors carry app message data only.
14. Route, query, session, and user facts come from `RequestContext`.
15. Server handlers may use `ServerContext` for app resources and I/O.
16. `ToClient` values are applied to page, layout, or shared-state models by constructor-named client handlers.
17. Local page messages are for browser-originated events and do not cross the wire.
18. `ClientSharedState` is per Mount by default.
19. Live connection state belongs to the app runtime.
20. Rich app-wide payloads use `ToClient` values.
21. User-owned app code is Mount-first under root `src/{mount_namespace}`. The exception is `src/api`, which is one global wire graph and has no public/admin subdivision.
22. Generated support modules live under `src/generated`.
23. Shared page views are pure enough for SSR, client rendering, and direct tests. They must not import transport, generated client effects, modem, browser setup, or route modules.
