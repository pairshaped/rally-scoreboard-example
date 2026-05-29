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

## Runtime Taxonomy

Use these terms consistently:

- `AuthenticationContext`: shared identity facts loaded from the browser session. It answers who the session represents.
- `RequestContext`: per-request or per-socket facts passed to server handlers. It carries route params, query params, session facts, and authenticated user facts.
- `ServerContext`: server-side resources such as DB handles, config, clocks, service clients, and logging. It must not carry current route params, query params, session facts, or authenticated user facts.
- `ClientSharedState`: per-Mount browser state shared by the Mount shell, layouts, and pages. It contains shell-level state such as signed-in display facts, authorization summaries, active section, league name, dark mode, and toast or flash state.
- SSR `ToClient` page data payload: boot-time server-emitted `ToClient` values produced by generated SSR execution of the route's boot requests. They seed the initial page model during hydration. They are not `ClientSharedState`.
- page `Model`: client-owned local UI state for a page or root client app.
- `backend.Model`: app-owned live server state for one Mount connection. It is server process state, not durable business data.
- `ToServer`: browser-to-server command vocabulary. Commands carry command fields only; route/query/session/user facts come from `RequestContext`.
- `ToClient`: server-to-browser result and event vocabulary. It is used for command outcomes, live events, and SSR page data hydration.

`ClientSharedState` and SSR `ToClient` page data are separate boot payloads. `ClientSharedState` initializes Mount shell/shared browser state. SSR `ToClient` page data initializes the current page model. They must use separate runtime storage names so one cannot overwrite the other during boot.

## Wire Graphs

The Generator Framework builds one shared API codec graph:

```text
shared/api/**/*.gleam
```

Client and server packages may import subsets of `shared/api` for packaging, but those subsets do not weaken the global wire-name rule. Moving a type to another module or directory does not fix a wire collision. Renaming the constructor does.

The Generator Framework validates constructor names within the shared API graph. Duplicate plain ETF constructor names fail generation before codegen. The check includes `ToServer` constructors, `ToClient` constructors, domain constructors, and any other public wire-visible custom type constructor. The check does not use module paths, type names, transport direction, arity, namespace prefixes, hashes, or generated identities to disambiguate values.

Diagnostics for codec graph collisions are part of the contract. The Generator Framework names the duplicate constructor, the plain ETF atom, every file/type involved, and the expected fix. Collision errors use Marmot-style diagnostics: plain language, exact locations, what the Generator Framework saw, why it is unsafe, and how the app author can fix it.

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
Msg for browser-originated events
form state
view helpers
browser-only UI data
client effects and JS FFI callbacks
```

Pages are a three-target concept. A route may have matching page modules in shared, client, and server targets:

```text
shared/src/shared/{mount}/pages/**/*.gleam
client/src/client/{mount}/pages/**/*.gleam
server/src/server/{mount}/pages/**/*.gleam
```

The shared page module owns the route's target-neutral view, view input helpers, pure data helpers, and boot request declaration. Its main view function is named `view`, and it is the first function after `init_requests` when `init_requests` exists. When a page has normal first-render data needs, the shared page module declares them with `init_requests() -> List(to_server.ToServer)`.

The client page module owns the browser page model, local `Msg`, browser-only behavior such as DOM effects, JS FFI, drag and drop, subscriptions, browser event handling, optional client-side `init`, local `update`, and client `ToClient` handlers.

The server page module owns server-only behavior such as page data loading, database access, authorization checks, provider/server API calls, optional server-side `init`, and command handlers.

The Generator Framework wires matching target modules together by route. It does not ask app authors to put all page code in one file and split that file into target-specific generated output.

Local page `Msg` values do not cross the wire. They are reserved for browser-originated page events such as clicks, input changes, timers, subscriptions, and JS FFI callbacks. Server results and pushed events cross the wire as `ToClient` values. Client `ToClient` handlers apply those values directly to page models; they do not mirror `ToClient` constructors into local `Msg` values.

Page modules may import `shared/api` domain and protocol types. They do not define wire-visible `ToServer`, `ToClient`, or wire domain types.

## Page Boot Requests

Page boot requests are the one true first-render data convention.

Shared page modules declare the normal first-render server requests for a route:

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

`init_requests` is the canonical boot wiring for the route. It takes no page model, `RequestContext`, `ServerContext`, or `ClientSharedState`. It does not decide whether data is already present and it does not load data itself.

Every user-owned `init_requests` function should have a function comment explaining that it is shared boot wiring consumed by both generated SSR and generated client init. Generated code that calls `init_requests` should also comment that the shared function is the source of truth, and that target-specific `init` hooks must call it when it is non-empty.

For a normal data-backed page, the app author writes `init_requests` and omits target-specific `init` functions. The Generator Framework supplies the boring target behavior:

- generated SSR executes the route's `init_requests`, maps each `ToServer` value to its server handler, and embeds the returned `ToClient` values as page-data hydration flags
- generated client init skips requests when SSR hydration already populated the page model
- generated client init sends `init_requests` over WebSocket when hydration is absent or the page model still needs data

Target-specific `init` functions exist only for custom behavior.

Client page modules may define `init` when browser startup needs custom logic:

```gleam
pub fn init(
  model model: Model,
  client_shared_state client_shared_state: ClientSharedState,
) -> #(Model, List(to_server.ToServer)) {
  case model.games {
    Loaded(_) -> #(model, [])
    _ -> #(model, shared_games.init_requests())
  }
}
```

Custom client `init` owns the conditional. It may inspect the page model, hydration state, browser-only state, or `ClientSharedState`, then return the `ToServer` requests still needed.

Server page modules may define `init` when SSR startup needs server-only request selection or extra boot requests:

```gleam
pub fn init(
  request_context request_context: RequestContext,
  server_context server_context: ServerContext,
) -> List(to_server.ToServer) {
  shared_games.init_requests()
}
```

Custom server `init` returns `ToServer` requests, not loaded `ToClient` values. Generated SSR still owns request execution and hydration encoding.

If a shared page defines non-empty `init_requests`, any custom client or server `init` for that route must call the shared page's `init_requests` rather than duplicating or replacing the request list. Target `init` functions may filter, augment, or defer those requests, but the shared request declaration remains the source of truth.

Static pages can omit `init_requests`, client `init`, and server `init`. SSR boots no page data for those routes.

The Generator Framework must flag inconsistencies:

- `init_requests` returns `ToServer` constructors that have no matching server handler
- a `ToServer` constructor from `init_requests` maps to more than one server handler
- a matching server handler has the wrong signature
- server dispatch maps a `ToServer` constructor to page `init` instead of the constructor-derived handler
- custom server `init` exists for a route with non-empty shared `init_requests` but does not call shared `init_requests`
- custom client `init` exists for a route with non-empty shared `init_requests` but does not call shared `init_requests`
- target `init` functions duplicate literal boot requests instead of using shared `init_requests`

A `ToServer.LoadGames` constructor maps to `load_games`, `ToServer.LoadTeam` maps to `load_team`, and so on. `init_requests` wires the page boot requests. Target `init` functions customize startup. Neither one replaces the `ToServer` handler convention.

## User-Owned Package Layout

User-owned app code is Mount-first. A Mount is a runnable app boundary mounted at a route root. The Mount owns shared page modules, client page modules, server page modules, backend state, SSR loaders, its shell, and Mount-specific policy.

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

`ToServer` is point-to-point command input for the current Mount connection. The Generator Framework never fans out a `ToServer` value and never forwards a `ToServer` value from one Mount to another Mount. A client command is valid only when the current Mount owns the discovered handler for that constructor.

The shared API graph may contain `ToServer` constructors handled by other Mounts. Generated dispatch makes those branches explicit, because dispatch is exhaustive over the global `ToServer` type, and the default behavior does not silently no-op. Other-Mount commands are invalid for the current Mount and go through a generated rejection path that can log an issue, emit a Mount-appropriate `ToClient` error when one exists, and return the backend model unchanged.

Each `ToServer` constructor has exactly one server handler in the app. The Generator Framework generates each Mount dispatch table from the global `ToServer` type and the handlers discovered for that Mount. Generated dispatch owns the exhaustive `ToServer` case under `backend.update`: owned constructors call handlers, and unowned constructors reject the invalid command.

The default handler convention maps a constructor to a snake-case function:

```text
LoadGeneral  -> load_general
SaveGeneral  -> save_general
DeleteWaiver -> delete_waiver
```

This rule includes page-data load commands. `ToServer.LoadGames` maps to `load_games`; it does not map to page `init`.

Handlers live in the server target under the matching Mount namespace. By default, page-specific server handlers live in the matching server page module, beside the page-specific queries and mapping code they use. `backend.gleam` is the server update boundary and default interception/delegation point.

```text
server/src/server/admin/pages/games.gleam
server/src/server/public/pages/standings.gleam
```

Shared server-only helpers are extracted to `server/helpers/...` only after at least two server modules use the same helper. The Generator Framework does not create `store.gleam`, `helpers/`, or another shared app layer by default.

Handlers receive constructor fields as named arguments, plus the Generator Framework-provided context. They do not receive the whole `ToServer` value.

Page-data handlers are the handlers for constructors returned by a shared page's `init_requests`. They return the `ToClient` values that populate the page:

```gleam
pub fn load_games(
  request_context request_context: RequestContext,
  server_context server_context: ServerContext,
) -> List(to_client.ToClient) {
  todo
}
```

Generated live dispatch sends each returned `ToClient` to the current client and leaves `backend.Model` unchanged. Generated SSR execution calls these same handlers for boot requests and embeds their returned `ToClient` values into SSR hydration.

Operation handlers that need backend state or generated effects use the backend handler signature:

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

## Client Page Model And ToClient Handlers

`ToClient` is the server emission vocabulary. Pages, layouts, and shared client state handle `ToClient` values through generated `to_client` dispatch and constructor-named client handlers. Generated `to_client` dispatch owns the exhaustive `ToClient` case for active handlers.

Page-owned client `ToClient` handlers live in client page modules. Layout or shared-state handlers live with those client modules.

A client page module has a normal TEA shape:

```gleam
pub type Model {
  Model(articles: List(article.Article), draft_title: String)
}

pub type Msg {
  DraftTitleChanged(String)
  SubmitClicked
  BrowserMeasuredHeight(Int)
}

pub fn init() -> Model {
  Model(articles: [], draft_title: "")
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  todo
}
```

Local `Msg` constructors describe client-originated page events. They do not repeat or rename `ToClient` constructors.

A client `ToClient` handler is a mini-update over the page model. Its function name is the snake_case form of the `ToClient` constructor name:

```gleam
pub fn article_comment_added(
  model model: Model,
  comment comment: article.Comment,
) -> #(Model, Effect(Msg)) {
  #(Model(..model, articles: [comment.article, ..model.articles]), effect.none())
}
```

Handlers receive the page model as the first argument, then constructor fields as named arguments. They do not receive the whole `ToClient` value. They return the updated page model plus an effect whose message type is the page's local `Msg`. The effect lets a server event start client-only follow-up work such as browser measurement, JS FFI, or a subscription callback without inventing a local message that only repeats the server event.

This mirrors server `ToServer` handler naming:

```text
ToServer.LoadGames       -> server handler load_games
ToServer.UpdateScore     -> server handler update_score

ToClient.GamesLoaded     -> client handler games_loaded
ToClient.GameUpdated -> client handler game_updated
```

The Generator Framework recognizes only the constructor-derived snake_case handler name for this convention. A generic `receive` function is not a `ToClient` handler. The Generator Framework fails generation when a discovered client `ToClient` handler has a signature that does not match the constructor fields. It also fails when a module declares interest in a `ToClient` constructor but the matching snake_case handler is missing. Constructors with no active handler follow the app's configured no-handler policy.

A `ToClient` constructor can be handled by more than one active client module. The Generator Framework fans the value out to every active handler for that constructor.

Generated Mount `to_client` dispatch owns the page-model plumbing for server events. It keeps a generated bundle of page models for the Mount, applies each `ToClient` value to the active page handlers, stores the returned page models back into that bundle, and batches any returned page effects. The hand-written Mount root stores that generated page-model bundle and delegates server events to generated `to_client` dispatch.

The hand-written Mount root owns route parsing, navigation, WebSocket registration, hydration boot flags, `ClientSharedState`, shell state such as dark mode, and shell view composition. It does not duplicate server event handling in a parallel local `Msg` vocabulary.

For client-originated page events, generated Mount `to_client` dispatch also exposes a page-message update entry point. The Mount root wraps page-local messages only when a browser event originates from the page view or from a page effect. Those wrappers are not used for server-emitted `ToClient` values.

The Generator Framework must flag inconsistencies:

- a client page declares a `ToClient` interest but the constructor-derived handler is missing
- a client `ToClient` handler omits the page model argument
- a client `ToClient` handler takes the whole `ToClient` value instead of constructor fields
- a client `ToClient` handler returns a local `Msg` instead of `#(Model, Effect(Msg))`
- a local page `Msg` constructor mirrors a `ToClient` constructor only to enter `update`
- generated `to_client` dispatch returns local page `Msg` values for server-emitted events

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

The shared target owns `ClientSharedState` and `ClientSharedStateMsg` because SSR and browser hydration need the same shape. The shared page target owns `init_requests`. The client target owns optional browser `init` and update. The server target owns optional server `init` and server handlers.

When `ClientSharedState` exists, page and layout update functions may return `Option(ClientSharedStateMsg)`. Generated root client code applies those messages through `ClientSharedState.update`.

Server-originated `ToClient` values never update `ClientSharedState` directly. Page, layout, or shared-state client handlers decide how a `ToClient` value changes local and shared client state.

`ClientSharedState` is not the SSR page data payload. SSR page data is a list of `ToClient` values produced by generated SSR execution of the current route's boot requests so the page model can start populated. `ClientSharedState` is Mount-level state that the shell and pages can read across routes.

## Backend State

`backend.Model` is app-owned state for one live SPA root connection. It is wider than one page and narrower than the whole BEAM node. It is shared across server handlers for that connection and changes through `backend.Msg` and `backend.update`.

`backend.Model` is live server state, not durable business data. Durable facts belong in the database or cache. `ServerContext` contains resources such as DB handles, config, clocks, service clients, and logging. `backend.Model` contains app-owned live state for one connection.

## Request Context

`RequestContext` is built during SSR boot, client page init/navigation, and authentication state changes. It carries route params, query params, session facts, and authenticated user facts.

`ToServer` constructors carry command-specific data only. Route, query, session, and user facts come from `RequestContext`.

`ServerContext` is app-defined process-scope server resources. It must not contain current route params, query params, session facts, or authenticated user facts.

## Authentication Runtime

Generated authentication helpers may issue short-lived sign-in codes for app-owned sign-in flows. Sign-in codes use the uppercase `0-9A-Z` alphabet. The Generator Framework normalizes both the lookup scope and submitted code by trimming whitespace and converting to uppercase before hashing or verifying.

Password sign-in is not part of the Scoreboard application contract. The sign-in page is `/sign_in`, and the supported sign-in mechanisms are emailed sign-in links, submitted sign-in codes, or SSO provider callbacks. There are no alternate password or code-specific sign-in routes.

The Generator Framework does not use an ambiguity-reduced sign-in code alphabet. The generated UI uses a readable font and input normalization, rather than making the runtime alphabet smaller.

The Generator Framework uses the full words `authentication` and `authorization` in generated paths, module names, comments, and docs. It does not use the abbreviation `auth`, because the abbreviation does not say whether code is proving identity or checking permission. Sign-in and sign-out routes use `sign_in` and `sign_out`; the Generator Framework does not use `login` or `logout` in generated route paths.

Generated metadata uses `declares_authorization` for the static fact that a page or handler declares an authorization hook. Runtime authorization decisions use names like `is_authorized` or `check_page_authorization`.

## Live Updates

Live updates use `ToClient` values.

```gleam
pub type ToClient {
  GameCreated(game: GameSnapshot)
  GameUpdated(game: GameSnapshot)
}
```

The browser routes every server-originated `ToClient` through the same generated `to_client` dispatch. Constructor-named client handlers signal client-side interest and apply the server event directly to page models. If multiple active handlers handle the constructor, the Generator Framework fans the value out to all of them. If no active handler handles the constructor, the configured no-handler policy applies.

The Generator Framework does not generate separate live-update topic or payload contract types.

## SSR And Hydration

SSR handlers serve the first HTTP request for a route. Instead of returning an empty shell and waiting for client-side boot, SSR handlers execute the route's boot requests and render the result into the HTML response.

The SSR contract:

- SSR handlers execute the route's shared `init_requests` on HTTP request. If custom server `init` exists, SSR executes the requests returned by that function instead. Both paths produce the same `ToClient` values the client would receive over WebSocket after sending those requests.
- The server applies the `ToClient` values to route render data and renders the shared Lustre view to an HTML string with `lustre/element.to_string`.
- The HTML response embeds the loaded page data as base64-encoded ETF `ToClient` values in a dedicated SSR page-data slot such as `__RUNTIME_SSR_TO_CLIENT__`. Route, params, and query are not embedded; the client derives them from `window.location` via `modem.initial_uri()`.
- The HTML response separately embeds the Mount `ClientSharedState` payload in `__RUNTIME_CLIENT_SHARED_STATE__`.
- Client init reads the embedded `ToClient` values as Lustre init flags. When hydration data exists, the client seeds its generated page-model bundle through the generated `to_client` dispatch path and can skip requests from `init_requests`. When hydration data is absent, client `init` can send `init_requests` over WebSocket.
- Client init reads the embedded `ClientSharedState` separately and passes it to the Mount shell/root app. Reading one boot payload must not delete or overwrite the other.
- After hydration, SPA navigation still runs client page `init` and sends needed `ToServer` requests through the WebSocket connection.
- Live fanout (`ToClient` broadcast via `pg`) continues as the post-boot update path.

Hydration in this project means client init consumes server-loaded data and starts populated. It does not mean DOM reconciliation. The client renders the same shared page view the server used, wrapped in its app chrome (topbar, shell). When the client has hydrated data, the page-content portion of the initial client render matches the SSR page HTML.

Shared page views are intentionally pure so they can be rendered by SSR, reused by the client, and tested directly without browser transport or WebSocket setup. Shared views accept data and action callbacks but must not import transport, generated client effects, modem, browser setup, or route modules.

The Scoreboard example's generated files describe the intended generated output shape for this contract. Implementing generator support for that output is a separate project.

## Generated Ownership

One `[[tools.rally.clients]]` entry defines one Mount. The Mount namespace derives generated paths only for files whose inputs are Mount-specific: routes, request context, backend dispatch, SSR, static handling, WebSocket handling, and `to_client` dispatch.

Mounts can enable local logging independently:

```toml
[[tools.rally.clients]]
namespace = "admin"
user_logging = true
issue_logging = true
```

Both logging flags default to `false` when omitted. the framework initializer writes both flags as `true` so new apps visibly opt in to local observability instead of inheriting hidden database writes. `user_logging` records authenticated user activity for the Mount; unauthenticated activity never writes user log rows. User log rows include `created_at`, user id, user email, session id, Mount, route, and message type. User email is stored because the Generator Framework's local system database is not joined to app-owned user tables. `issue_logging` records runtime issues for the Mount and does not require authentication, but includes authenticated user id and email when they are available. Issue log rows include `created_at`, Mount, route, kind, message, optional message type, optional trace, and optional context. Timing is not part of the local logging schema unless the runtime already has that timing without extra instrumentation. Normal server logs and query timing logs are not written to the Generator Framework's system DB; query timing is dev-only logger output. Both logging modes store Mount and route, not page module names, because logs describe handled app activity rather than UI implementation. The local logging schema has `user_logs` and `issue_logs`, separate from jobs and app data.

The Generator Framework's system database has an app-facing system portal. The portal lets authorized users examine and search user logs, issue logs, and jobs from inside the deployed app. This makes local observability useful without a third-party service and gives teams a place to inspect background job state alongside runtime issues. The portal is a generated Mount or reserved system route; application Mounts do not hand-roll access to system tables.

The Generator Framework has first-class system migrations so framework-owned tables and app-owned system extensions are visible, versioned, and runnable through the same migration workflow as app data.

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
client/src/generated/public/to_client.gleam

client/src/generated/admin/router.gleam
client/src/generated/admin/to_client.gleam
```

Client `protocol_wire`, `codec`, transport, setup, and effect modules are generated once because the shared API graph and transport runtime are package-level. Client routers and `to_client` dispatch are Mount-specific because they depend on active routes and active page handlers.

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

server/src/generated/runtime/server_generated_runtime_effect_state_ffi.erl
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

The Generator Framework does not generate Mount RPC dispatch, page dispatch, or server-side `ToClient` handler stubs for the root API path. Page init, `ToServer`, and `ToClient` use the package-level protocol wire module.

The Generator Framework does not create additional `generated/` directories under user-owned Mount namespaces such as `client/public`, `server/public`, or `shared/public`.

Generated Erlang FFI files follow the same ownership rule. A generated `.erl` file lives under the owning package's `src/generated` tree beside the Gleam module that imports it. The Generator Framework does not write generated `.erl` files into package `src/` roots.

Good:

```text
server/src/generated/server_generated_protocol_wire_ffi.erl
server/src/generated/server_generated_protocol_atoms_ffi.erl
server/src/generated/runtime/server_generated_runtime_db_ffi.erl
```

Avoid:

```text
server/src/generated/public/runtime/server_public_generated_runtime_db_ffi.erl
server/src/generated/admin/runtime/server_admin_generated_runtime_db_ffi.erl
server/src/server_public_generated_protocol_wire_ffi.erl
server/src/server_public_generated_runtime_db_ffi.erl
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

`ToClient` values are global server emissions. They may be delivered to any active client handler in any Mount that handles the constructor. This is intentionally different from `ToServer`: commands are current-Mount input, while server emissions are handler-driven app events and results. For example, an admin score command may emit `GameUpdated`, and public pages may handle that `ToClient` value through their active `game_updated` handlers.

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
11. Every `ToServer` constructor has exactly one server handler in the app.
12. `ToServer` constructors carry command data only.
13. Route, query, session, and user facts come from `RequestContext`.
14. Server handlers may use `ServerContext` for app resources and I/O.
15. `ToClient` values are applied to page, layout, or shared-state models by constructor-named client handlers.
16. Local page `Msg` values are for browser-originated events and do not cross the wire.
17. Each Mount has a user-owned `backend.gleam` with `Msg`, `init`, and `update`; the `Model` type lives in sibling `model.gleam` so generated dispatch can import it without a cyclic dependency on `backend.gleam`.
18. `backend.Msg` includes a client-message branch carrying `ToServer` and `RequestContext`.
19. `backend.update` may intercept `ToServer` messages or delegate to generated dispatch. The generated dispatch module is emitted at `generated/{mount_namespace}/dispatch.gleam` and imported as `generated_dispatch`.
20. Generated dispatch exhaustively matches the global `ToServer` type for each Mount. Constructors owned by the current Mount call server page handlers with constructor fields. Constructors owned by other Mounts are invalid for the current Mount and use a generated rejection path instead of silently returning `effect.none()`. The dispatch entry point is `generated_dispatch.to_server(msg, request_context, server_context, backend_model) -> #(Model, Effect(ToClient))`.
21. The Generator Framework never fans out or forwards `ToServer` values across Mounts. A `ToServer` command is handled only by the Mount connection that received it.
22. Generated `to_client` dispatch exhaustively matches `ToClient`, routes constructor fields to active client handlers, stores returned page models, and batches returned page effects. All server-originated `ToClient` values use the same `to_client` dispatch path.
23. `ToClient` delivery is global and handler-driven. Any active client handler in any Mount may opt into any `ToClient` constructor.
24. `ClientSharedState` is per Mount by default.
25. `backend.Model` is per live SPA root connection.
26. App-wide string notices use the built-in layout/client-shell lane.
27. Rich app-wide payloads use `ToClient` values.
28. `ToServer` uses the command lane without transport acknowledgements; app-visible outcomes use `ToClient`.
29. User-owned app code is Mount-first: `server/src/server/{mount_namespace}`, `client/src/client/{mount_namespace}`, and `shared/src/shared/{mount_namespace}`. The exception is `shared/src/shared/api`, which is one global wire graph and has no public/admin subdivision.
30. Each package has exactly one generated root: `client/src/generated`, `server/src/generated`, or `shared/src/generated`.
31. Generated files are Mount-namespaced only when they depend on Mount-specific inputs. Mount-specific generated files live under `generated/public` or `generated/admin`.
32. Generated runtime helpers, codecs, package protocol wire modules, SQL modules, setup modules, and transport modules are package-level generated files. They live under `generated`, `generated/runtime`, or `generated/sql`, not under `generated/{mount_namespace}/runtime`.
33. Generated Erlang FFI files live under the owning package's generated root beside the Gleam module that imports them. The Generator Framework does not write generated `.erl` files into package `src/` roots.
34. Client shells use Modem for same-Mount navigation and leave cross-Mount, sign-out, external, and SSR-intent links as normal anchors.
35. Mount logging is explicit. `user_logging` and `issue_logging` default to `false` when omitted; the framework initializer writes both as `true` in each Mount block. User logging only writes for authenticated users and stores user id plus email. Issue logging writes runtime issues for the Mount with or without authentication, including user id and email when known.
36. Generated sign-in codes use uppercase `0-9A-Z`; verification trims and normalizes the lookup scope and submitted code to uppercase before hashing.
37. SSR handlers execute the route's boot requests on HTTP request, render the same shared Lustre view the client uses, and embed the loaded page data as base64 ETF `ToClient` values in a dedicated SSR page-data slot. Route, params, and query are derived from the current browser URL rather than embedded as SSR flags.
38. Client init hydration means consuming server-embedded SSR `ToClient` page data through generated `to_client` dispatch so the generated page-model bundle starts populated, skipping requests from shared `init_requests` when hydration data exists. It does not mean DOM reconciliation.
39. Shared page views are intentionally pure so they can be rendered by SSR, reused by the client, and tested directly without browser transport or WebSocket setup. Shared views accept data and action callbacks but must not import transport, generated client effects, modem, browser setup, or route modules.
40. SPA navigation after initial hydration still runs client page `init` and sends needed `ToServer` requests through the WebSocket connection. Live fanout (`ToClient` broadcast via `pg`) continues as the post-boot update path.
