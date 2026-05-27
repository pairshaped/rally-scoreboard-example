# Default to Root API Contracts

The Generator Framework's wire contracts live under `shared/api`. Pages own local UI state and rendering. The `shared/api` tree owns the types that cross the wire.

The shared package targets both Erlang and JavaScript, so every wire-visible type must compile on both targets. Types in `server/` or `client/` are target-specific and cannot be wire payloads.

## Root API Layout

The Generator Framework uses one shared API graph for wire-visible app types:

```text
shared/src/shared/api/to_server.gleam
shared/src/shared/api/to_client.gleam
shared/src/shared/api/domain/**/*.gleam
shared/src/shared/api/**/*.gleam

server/src/server/public/backend.gleam
server/src/server/public/model.gleam
server/src/server/admin/backend.gleam
server/src/server/admin/model.gleam
```

Any public custom type named `ToServer` under `shared/api` contributes client-to-server command constructors. Constructor fields are the command payload.

```gleam
pub type ToServer {
  AddArticleComment(body: String)
  DeleteArticleComment(comment_id: Int)
}
```

Any public custom type named `ToClient` under `shared/api` contributes server-to-client result and event constructors. Constructor fields are the delivered payload.

```gleam
pub type ToClient {
  ArticleCommentAdded(comment: article.Comment)
  ArticleFavoriteCountUpdated(count: Int)
}
```

Other public custom types under `shared/api` are reusable wire-visible domain shapes. They do not define one wrapper type per message just to make handlers receive a message-shaped value. The `ToServer` and `ToClient` unions are the message-shaped values.

Module structure under `shared/api` is for code organization and JavaScript packaging. It does not create wire identity. API modules are not Mount namespaces. Public/admin Mount boundaries are expressed by the user-owned app code and generated Mount modules, not by `shared/api/public` or `shared/api/admin` protocol roots.

The preferred shared API shape is:

```text
shared/src/shared/api/to_server.gleam
shared/src/shared/api/to_client.gleam
shared/src/shared/api/domain/game.gleam
shared/src/shared/api/domain/user.gleam
shared/src/shared/api/domain/**/*.gleam
```

Apps may split the shared API into additional modules for readability or packaging, but those modules are still one global wire graph. Any constructor that crosses the wire needs a unique plain ETF atom in the whole shared API graph.

The Generator Framework uses client/server language for transport messages. `ToServer` and `ToClient` match the Generator Framework's package and runtime vocabulary. `backend.gleam` names the server-side app state boundary, not a separate protocol vocabulary.

## Wire Graphs

The Generator Framework builds one shared API codec graph:

```text
shared/api/**/*.gleam
```

Client and server packages may import subsets of `shared/api` for packaging, but those subsets do not weaken the global wire-name rule. Moving a type to another module or directory does not fix a wire collision. Renaming the constructor does.

The Generator Framework validates constructor names within the shared API graph. Duplicate plain ETF constructor names fail generation before codegen. The check includes `ToServer` constructors, `ToClient` constructors, domain constructors, and any other public wire-visible custom type constructor. The check does not use module paths, type names, transport direction, arity, namespace prefixes, hashes, or generated identities to disambiguate values.

Diagnostics for codec graph collisions are part of the contract. The Generator Framework must name the duplicate constructor, the plain ETF atom, every file/type involved, and the expected fix. Collision errors should use Marmot-style diagnostics: plain language, exact locations, what the Generator Framework saw, why it is unsafe, and how the app author can fix it.

```text
Duplicate ETF constructor `User` in the shared API codec graph.

Plain ETF uses constructor atoms without module or type identity, so the Generator Framework cannot
safely decode both of these values:

- shared/api/domain/user.gleam
  User.User(id: Int)

- shared/api/domain/admin_user.gleam
  AdminUser.User(id: Int)

Rename one constructor so every wire-visible constructor in shared/api has
a unique plain ETF atom.
```

## Page Boundaries

Pages own local UI concerns:

```text
Model
Msg
form state
view helpers
browser-only UI data
local mapping functions
```

Local page `Msg` values do not cross the wire. Server results and pushed events cross the wire as `ToClient` values, then page or layout receivers map them into local messages.

Page modules may import `shared/api` domain and protocol types. They do not define wire-visible `ToServer`, `ToClient`, or wire domain types.

## User-Owned Package Layout

User-owned app code is Mount-first. A Mount is a runnable app boundary mounted at a route root. The Mount owns page views, client pages, receivers, backend state, SSR loaders, its shell, and Mount-specific policy.

The shared package has one exception: `shared/api` is the wire graph and is not Mount-namespaced. It does not use `shared/api/public` or `shared/api/admin`.

Shared API code lives under:

```text
shared/src/shared/api/to_server.gleam
shared/src/shared/api/to_client.gleam
shared/src/shared/api/domain/**/*.gleam
```

Shared public UI code lives under:

```text
shared/src/shared/public/pages/**/*.gleam
shared/src/shared/public/client_shared_state.gleam
```

Shared admin UI code lives under:

```text
shared/src/shared/admin/pages/**/*.gleam
shared/src/shared/admin/client_shared_state.gleam
```

Public client and server user code lives under:

```text
client/src/client/public/pages/**/*.gleam
client/src/client/public/receivers.gleam
client/src/client/public/client_shared_state.gleam

server/src/server/public/backend.gleam
server/src/server/public/model.gleam
server/src/server/public/pages/**/*.gleam
server/src/server/public/client_shared_state_loader.gleam
server/src/server/public/shell.html
```

Admin client and server user code lives under:

```text
client/src/client/admin/pages/**/*.gleam
client/src/client/admin/receivers.gleam
client/src/client/admin/client_shared_state.gleam

server/src/server/admin/backend.gleam
server/src/server/admin/model.gleam
server/src/server/admin/pages/**/*.gleam
server/src/server/admin/client_shared_state_loader.gleam
server/src/server/admin/shell.html
```

Shared server-only helpers live under:

```text
server/src/server/helpers/**/*.gleam
```

Shared client-only helpers live under:

```text
client/src/client/helpers/**/*.gleam
```

Shared target-neutral UI helpers live under:

```text
shared/src/shared/components/**/*.gleam
shared/src/shared/helpers/**/*.gleam
```

Do not organize the shared API under `shared/src/shared/api/public` or `shared/src/shared/api/admin`. Mount directories are fine for shared UI modules because pages do not cross the wire.

## Backend And Server Handlers

Each Mount has one server backend module. The backend module is the server-side update boundary for that live SPA root.

`backend.Model` lives in `server/{mount_namespace}/model.gleam`, next to `backend.gleam`. Generated dispatch and server handlers need the `Model` type in their signatures (both return `#(Model, Effect(ToClient))`). Keeping `Model` outside `backend.gleam` lets generated dispatch import the type without forcing a cyclic dependency on `backend.gleam`, which itself imports generated dispatch.

```gleam
// server/src/server/public/model.gleam
pub type Model {
  Model(read_only: Bool)
}
```

```gleam
// server/src/server/public/backend.gleam
import generated/public/dispatch as generated_dispatch
import server/public/model.{type Model, Model}

pub type Msg {
  FromClient(to_server.ToServer, RequestContext)
  SessionConnected
  SessionDisconnected
}

pub fn init() -> Model {
  Model(read_only: False)
}

pub fn update(
  msg msg: Msg,
  model model: Model,
  server_context server_context: ServerContext,
) -> #(Model, Effect(to_client.ToClient)) {
  case msg {
    FromClient(to_server_msg, request_context) ->
      generated_dispatch.to_server(
        msg: to_server_msg,
        request_context:,
        server_context:,
        backend_model: model,
      )

    SessionConnected ->
      #(model, effect.none())

    SessionDisconnected ->
      #(model, effect.none())
  }
}
```

The generated dispatch module is emitted at `generated/{mount_namespace}/dispatch.gleam`. Backend modules import it under the alias `generated_dispatch` so call sites read `generated_dispatch.to_server(...)`.

`ToServer` is one branch of backend `Msg`, not the whole backend message type. Backend `Msg` also receives server-local events such as timers, job results, connection events, and pubsub events.

The backend update may intercept, reject, wrap, or delegate a `ToServer` message. The default path delegates to generated dispatch. This keeps a single server policy/state boundary while preserving generated page routing.

Each `ToServer` constructor has exactly one server handler. The Generator Framework generates the dispatch table from the Mount `ToServer` type and discovered server handlers. Generated dispatch owns the exhaustive `ToServer` case under `backend.update`.

The default handler convention maps a constructor to a snake-case function:

```text
LoadGeneral  -> load_general
SaveGeneral  -> save_general
DeleteWaiver -> delete_waiver
```

Handlers live in the server target under the matching Mount namespace. By default, page-specific server handlers live in the matching server page module, beside the page-specific queries and mapping code they use. `backend.gleam` remains the server update boundary and default interception/delegation point.

```text
server/src/server/admin/pages/games.gleam
server/src/server/public/pages/standings.gleam
```

Shared server-only helpers are extracted to `server/helpers/...` only after at least two server modules use the same helper. The Generator Framework does not create `store.gleam`, `helpers/`, or another shared app layer by default.

Handlers receive constructor fields as named arguments, plus the Generator Framework-provided context. They do not receive the whole `ToServer` value.

```gleam
import server/public/model.{type Model}

pub fn add_article_comment(
  body body: String,
  request_context request_context: RequestContext,
  server_context server_context: ServerContext,
  backend_model backend_model: Model,
) -> #(Model, Effect(to_client.ToClient)) {
  todo
}
```

The Generator Framework fails generation when a `ToServer` constructor has no handler or more than one matching handler. Handler signature mismatches fail during generation when the Generator Framework can explain them, or during compilation when the generated dispatch calls the handler.

## Client Receivers

`ToClient` is the server emission vocabulary. Pages, layouts, and shared client state may receive `ToClient` values through generated receiver dispatch or explicit receiver functions. Generated receiver dispatch owns the exhaustive `ToClient` case for active receivers.

Client receivers live with the client code that owns the local `Msg` they produce. Page-owned receivers live in page modules. Layout or shared-state receivers live with those client modules.

A receiver maps constructor fields into local messages:

```gleam
pub fn article_comment_added_to_client(comment comment: article.Comment) -> Msg {
  ReceivedArticleCommentAdded(comment)
}
```

Apps may expose a user-owned receiver hub per Mount. In that shape, generated client receiver dispatch delegates to the hub and the hub returns the mounted page or layout messages to dispatch into the Lustre app. This keeps route-specific receiver policy in user code while preserving the generated transport boundary.

A `ToClient` constructor can be accepted by more than one active receiver. The Generator Framework drops opportunistic messages with no active receiver when the app declares that behavior. Constructors with no receiver anywhere are generation warnings or errors according to policy.

## Client Shared State

Each named Mount gets its own `ClientSharedState` contract by default:

```text
shared/src/shared/public/client_shared_state.gleam
client/src/client/public/client_shared_state.gleam
server/src/server/public/client_shared_state_loader.gleam

shared/src/shared/admin/client_shared_state.gleam
client/src/client/admin/client_shared_state.gleam
server/src/server/admin/client_shared_state_loader.gleam
```

The shared target owns `ClientSharedState` and `ClientSharedStateMsg` because SSR and browser hydration need the same shape. The client target owns browser `init` and `update`. The server target owns SSR `load`.

When `ClientSharedState` exists, page and layout update functions may return `Option(ClientSharedStateMsg)`. Generated root client code applies those messages through `ClientSharedState.update`.

Server-originated `ToClient` values never update `ClientSharedState` directly. Page, layout, or shared-state receiver code decides how a received API value changes local and shared client state.

## Backend State

`backend.Model` is app-owned state for one live SPA root connection. It is wider than one page and narrower than the whole BEAM node. It is shared across server handlers for that connection and changes through `backend.Msg` and `backend.update`.

`backend.Model` is live server state, not durable business data. Durable facts belong in the database or cache. `ServerContext` contains resources such as DB handles, config, clocks, service clients, and logging. `backend.Model` contains app-owned live state for one connection.

## Request Context

`RequestContext` is built during SSR load, client page init/navigation, and authentication state changes. It carries route params, query params, session facts, and authenticated user facts.

`ToServer` constructors carry command-specific data only. Route, query, session, and user facts come from `RequestContext`.

`ServerContext` is app-defined process-scope server resources. It must not contain current route params, query params, session facts, or authenticated user facts.

## Authentication Runtime

Generated authentication helpers may issue short-lived sign-in codes for app-owned sign-in flows. Sign-in codes use the uppercase `0-9A-Z` alphabet. The Generator Framework normalizes both the lookup scope and submitted code by trimming whitespace and converting to uppercase before hashing or verifying.

The Generator Framework does not use an ambiguity-reduced sign-in code alphabet. The generated UI should use a readable font and input normalization, rather than making the runtime alphabet smaller.

The Generator Framework uses the full words `authentication` and `authorization` in generated paths, module names, comments, and docs. It does not use the abbreviation `auth`, because the abbreviation does not say whether code is proving identity or checking permission. Sign-in and sign-out routes use `sign_in` and `sign_out`; the Generator Framework does not use `login` or `logout` in generated route paths.

Generated metadata uses `declares_authorization` for the static fact that a page or handler declares an authorization hook. Runtime authorization decisions use names like `is_authorized` or `check_page_authorization`.

## Live Updates

Live updates use `ToClient` values.

```gleam
pub type ToClient {
  GameScoreUpdated(update: GameScoreUpdate)
  StandingsUpdated(rows: List(StandingRow))
}
```

The browser receives every server-originated `ToClient` through the same receiver dispatch. Receiver handlers signal client-side interest. If multiple active receivers handle the constructor, the Generator Framework fans the value out to all of them. If no active receiver handles the constructor, the configured no-receiver policy applies.

The Generator Framework does not generate separate live-update topic or payload contract types.

## Generated Ownership

One `[[tools.rally.clients]]` entry defines one Mount. The Mount namespace derives generated paths only for files whose inputs are Mount-specific: routes, request context, backend dispatch, SSR, static handling, WebSocket handling, and receiver dispatch.

Mounts can enable local logging independently:

```toml
[[tools.rally.clients]]
namespace = "admin"
user_logging = true
issue_logging = true
```

Both logging flags default to `false` when omitted. the framework initializer writes both flags as `true` so new apps visibly opt in to local observability instead of inheriting hidden database writes. `user_logging` records authenticated user activity for the Mount; unauthenticated activity never writes user log rows. User log rows include `created_at`, user id, user email, session id, Mount, route, and message type. User email is stored because the Generator Framework's local system database is not joined to app-owned user tables. `issue_logging` records runtime issues for the Mount and does not require authentication, but includes authenticated user id and email when they are available. Issue log rows include `created_at`, Mount, route, kind, message, optional message type, optional trace, and optional context. Timing is not part of the local logging schema unless the runtime already has that timing without extra instrumentation. Normal server logs and query timing logs are not written to the Generator Framework's system DB; query timing is dev-only logger output. Both logging modes store Mount and route, not page module names, because logs describe handled app activity rather than UI implementation. The local logging schema has `user_logs` and `issue_logs`, separate from jobs and app data.

The Generator Framework's system database is meant to have an app-facing system portal. The portal will let authorized users examine and search user logs, issue logs, and jobs from inside the deployed app. This makes local observability useful without a third-party service and gives teams a place to inspect background job state alongside runtime issues. The portal is a future generated Mount or reserved system route; application Mounts do not hand-roll access to system tables.

The current generated `system_db.gleam` owns the system schema directly. That is acceptable for the Scoreboard target, but it should be broken out soon. The Generator Framework should have first-class system migrations so framework-owned tables and app-owned system extensions are visible, versioned, and runnable through the same migration workflow as app data.

User-authored app code is namespaced by Mount in every target:

```text
server/public
shared/public
client/public

server/admin
shared/admin
client/admin
```

The API contract uses `shared/api` with no public/admin subdivision because it is the global wire boundary. Shared page/view modules may still use public/admin Mount directories because pages do not cross the wire.

Each package has one generated root:

```text
client/src/generated
server/src/generated
shared/src/generated
```

Generated code is Mount-namespaced only when the file depends on the Mount. Generated runtime helpers, codecs, protocol wire modules, database boot code, and SQL output are package-level generated files.

The shared package generated layout is:

```text
shared/src/generated/public/route.gleam
shared/src/generated/admin/route.gleam
```

`route.gleam` is Mount-specific because routes are Mount-specific.

The client package generated layout is:

```text
client/src/generated/setup.gleam
client/src/generated/setup_ffi.mjs
client/src/generated/transport.gleam
client/src/generated/transport_ffi.mjs
client/src/generated/protocol_wire.mjs
client/src/generated/codec.gleam
client/src/generated/codec_ffi.mjs
client/src/generated/router.gleam
client/src/generated/router_ffi.mjs

client/src/generated/runtime/effect.gleam
client/src/generated/runtime/client_effect_ffi.mjs
client/src/generated/runtime/authentication.gleam

client/src/generated/public/router.gleam
client/src/generated/public/receiver_dispatch.gleam

client/src/generated/admin/router.gleam
client/src/generated/admin/receiver_dispatch.gleam
```

Client `protocol_wire`, `codec`, transport, setup, and effect modules are generated once because the shared API graph and transport runtime are package-level. Client routers and receiver dispatch are Mount-specific because they depend on active routes and active page receivers.

Client shells use Modem for same-Mount browser navigation. Generated routers expose `parse_uri(uri: Uri) -> Route` and `route_to_path(route:) -> String`; the shell reads the initial URI from Modem, pushes same-Mount routes through Modem, and reloads page data when Modem reports a URI change.

The Generator Framework does not ask Modem to intercept every internal link. Links that cross Mounts, leave the Generator Framework app, perform sign-out, or intentionally depend on SSR remain normal anchors. Same-Mount page links may prevent the default click and dispatch a local navigation message.

The server package generated layout is:

```text
server/src/generated/entry.gleam
server/src/generated/protocol_wire.gleam
server/src/generated/static_handler.gleam
server/src/generated/ws_runtime.gleam
server/src/generated/server_generated_protocol_atoms_ffi.erl
server/src/generated/server_generated_protocol_wire_ffi.erl

server/src/generated/runtime/authentication.gleam
server/src/generated/runtime/db.gleam
server/src/generated/runtime/effect.gleam
server/src/generated/runtime/effect_runner.gleam
server/src/generated/runtime/effect_state.gleam
server/src/generated/runtime/env.gleam
server/src/generated/runtime/jobs.gleam
server/src/generated/runtime/session.gleam
server/src/generated/runtime/static.gleam
server/src/generated/runtime/system.gleam
server/src/generated/runtime/system_db.gleam
server/src/generated/runtime/trace.gleam

server/src/generated/runtime/server_generated_runtime_authentication_ffi.erl
server/src/generated/runtime/server_generated_runtime_db_ffi.erl
server/src/generated/runtime/server_generated_runtime_effect_state_ffi.erl
server/src/generated/runtime/server_generated_runtime_system_db_ffi.erl
server/src/generated/runtime/server_generated_runtime_trace_ffi.erl

server/src/generated/sql/**/*.gleam

server/src/generated/public/dispatch.gleam
server/src/generated/public/request_context.gleam
server/src/generated/public/router.gleam
server/src/generated/public/ssr_handler.gleam
server/src/generated/public/ws_handler.gleam

server/src/generated/admin/dispatch.gleam
server/src/generated/admin/request_context.gleam
server/src/generated/admin/router.gleam
server/src/generated/admin/ssr_handler.gleam
server/src/generated/admin/ws_handler.gleam
```

Server runtime modules under `server/src/generated/runtime` are generated once. A runtime module does not become Mount-specific just because two Mounts call it. If a runtime helper needs per-Mount state, it accepts a Mount key or stores scoped values internally; the Generator Framework does not duplicate the whole module under `generated/public/runtime` and `generated/admin/runtime`.

Server `dispatch`, `request_context`, `router`, `ssr_handler`, and `ws_handler` are Mount-specific. The static asset handler is generated once at `server/src/generated/static_handler.gleam` because all Mounts serve the same client build tree. The WebSocket runtime is generated once at `server/src/generated/ws_runtime.gleam`; Mount WebSocket handlers adapt their route and backend modules into that runtime. Mount modules import package-level generated runtime modules from `generated/runtime` and package-level protocol modules from `generated`.

The Generator Framework does not generate Mount RPC dispatch, page dispatch, or server-side receiver stubs for the root API path. Page init, `ToServer`, and `ToClient` use the package-level protocol wire module.

The Generator Framework does not create additional `generated/` directories under user-owned Mount namespaces such as `client/public`, `server/public`, or `shared/public`.

Generated Erlang FFI files follow the same ownership rule. A generated `.erl` file lives under the owning package's `src/generated` tree beside the Gleam module that imports it. The Generator Framework does not write generated `.erl` files into package `src/` roots.

Good:

```text
server/src/generated/server_generated_protocol_wire_ffi.erl
server/src/generated/server_generated_protocol_atoms_ffi.erl
server/src/generated/runtime/server_generated_runtime_authentication_ffi.erl
server/src/generated/runtime/server_generated_runtime_db_ffi.erl
```

Avoid:

```text
server/src/generated/public/runtime/server_public_generated_runtime_authentication_ffi.erl
server/src/generated/admin/runtime/server_admin_generated_runtime_authentication_ffi.erl
server/src/server_public_generated_protocol_wire_ffi.erl
server/src/server_public_generated_runtime_authentication_ffi.erl
server/src/server_generated_runtime_db_ffi.erl
```

## Transport

The transport lane selects the root type:

```text
ToServer
ToClient
```

The browser loader decides which API modules it imports. Public and admin loaders stay separate so each bundle can omit the other Mount's page code and any API modules it never imports. That packaging boundary does not create wire identity.

The root type drives top-down encoding and decoding. The Generator Framework does not infer payload identity by trying every known type. ETF carries runtime values. The Generator Framework's generated codec graph supplies the root type information needed by the JavaScript and BEAM bridge.

Type aliases are transparent on the wire, as they are in Gleam. Domain identities that need runtime distinction use wrapper custom types.

`ToServer` frames are fire-and-forget commands. The client does not register a response callback for them and the server does not send a transport acknowledgement. Server operation outcomes travel as `ToClient` pushes. Root API transport does not expose an RPC lane.

## Rules

1. Wire-visible types live under `shared/api`.
2. Public custom types named `ToServer` under `shared/api` define command constructors.
3. Public custom types named `ToClient` under `shared/api` define server-emitted result and event constructors.
4. Other public custom types under `shared/api` are domain types.
5. Live updates use `ToClient`; the Generator Framework does not generate separate live-update topic or payload types.
6. Types under `server/`, `client/`, page modules, and layout modules do not cross the wire.
7. Codec generation validates the selected `shared/api` graph.
8. Module paths and directories under `shared/api` are code organization only; they do not contribute wire identity.
9. Client packages may import subsets of `shared/api` for JavaScript packaging.
10. Duplicate plain ETF constructor names inside the shared API graph are generation errors. The uniqueness check includes `ToServer`, `ToClient`, and domain constructors, and does not consider module path, type name, transport direction, arity, namespace prefix, hash, or generated identity.
11. Every `ToServer` constructor has exactly one server handler.
12. `ToServer` constructors carry command data only.
13. Route, query, session, and user facts come from `RequestContext`.
14. Server handlers may use `ServerContext` for app resources and I/O.
15. `ToClient` values are mapped into local page, layout, or shared-state messages by receivers.
16. Local page `Msg` values do not cross the wire.
17. Each Mount has a user-owned `backend.gleam` with `Msg`, `init`, and `update`; the `Model` type lives in sibling `model.gleam` so generated dispatch can import it without a cyclic dependency on `backend.gleam`.
18. `backend.Msg` includes a client-message branch carrying `ToServer` and `RequestContext`.
19. `backend.update` may intercept `ToServer` messages or delegate to generated dispatch. The generated dispatch module is emitted at `generated/{mount_namespace}/dispatch.gleam` and imported as `generated_dispatch`.
20. Generated dispatch exhaustively matches `ToServer` and calls server page handlers with constructor fields. The dispatch entry point is `generated_dispatch.to_server(msg, request_context, server_context, backend_model) -> #(Model, Effect(ToClient))`.
21. Generated receiver dispatch exhaustively matches `ToClient` and routes constructor fields to active receivers. All server-originated `ToClient` values use the same receiver path.
22. `ClientSharedState` is per Mount by default.
23. `backend.Model` is per live SPA root connection.
24. App-wide string notices use the built-in layout/client-shell lane.
25. Rich app-wide payloads use `ToClient` values.
26. `ToServer` uses the command lane without transport acknowledgements; app-visible outcomes use `ToClient`.
27. User-owned app code is Mount-first: `server/src/server/{mount_namespace}`, `client/src/client/{mount_namespace}`, and `shared/src/shared/{mount_namespace}`. The exception is `shared/src/shared/api`, which is one global wire graph and has no public/admin subdivision.
28. Each package has exactly one generated root: `client/src/generated`, `server/src/generated`, or `shared/src/generated`.
29. Generated files are Mount-namespaced only when they depend on Mount-specific inputs. Mount-specific generated files live under `generated/public` or `generated/admin`.
30. Generated runtime helpers, codecs, package protocol wire modules, SQL modules, setup modules, and transport modules are package-level generated files. They live under `generated`, `generated/runtime`, or `generated/sql`, not under `generated/{mount_namespace}/runtime`.
31. Generated Erlang FFI files live under the owning package's generated root beside the Gleam module that imports them. The Generator Framework does not write generated `.erl` files into package `src/` roots.
32. Client shells use Modem for same-Mount navigation and leave cross-Mount, sign-out, external, and SSR-intent links as normal anchors.
33. Mount logging is explicit. `user_logging` and `issue_logging` default to `false` when omitted; the framework initializer writes both as `true` in each Mount block. User logging only writes for authenticated users and stores user id plus email. Issue logging writes runtime issues for the Mount with or without authentication, including user id and email when known.
34. Generated sign-in codes use uppercase `0-9A-Z`; verification trims and normalizes the lookup scope and submitted code to uppercase before hashing.
