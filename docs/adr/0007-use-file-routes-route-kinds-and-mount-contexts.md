# Use File Routes, Route Kinds, And Mount Contexts

The generator derives Mount routes from route modules. App authors add, move, and name modules; the generator emits the route type, URL parser, path builder, page glue, and navigation helpers.

The generated routing contract follows an Elm Land style convention: the file path is the route declaration.

## File Routes

Normal page modules use the `.gleam` suffix and are mounted through the Mount shell. The root source page module declares the route file path. Target-neutral view code lives beside the Mount under `views`.

```text
src/public/pages/games.gleam
src/public/pages/games/[id].gleam
src/public/pages/teams/[slug].gleam
src/admin/pages/games.gleam
src/public/views/games.gleam
src/public/views/games/[id].gleam
src/public/views/teams/[slug].gleam
src/admin/views/games.gleam
```

The generator keeps those root modules in the unified source tree. Target-specific page declarations and imports carry target annotations. Generated route and page glue lives under `src/generated/proute`:

```text
src/generated/proute/public/routes.gleam
src/generated/proute/public/page_input.gleam
src/generated/proute/public/pages.gleam

src/generated/proute/admin/routes.gleam
src/generated/proute/admin/page_input.gleam
src/generated/proute/admin/pages.gleam
```

The generator derives the route from the root page path and wires the unified page module into generated route/page glue. Client-only behavior stays behind JavaScript target annotations. Server-only behavior stays behind Erlang target annotations. Target-neutral views and page helpers stay unannotated when they compile for both targets.

Normal pages use one first-render data convention across targets:

- shared page modules may declare `init_requests() -> List(ToServer)`
- client page modules may define `init(...)` for custom browser startup decisions
- client page modules define constructor-named `ToClient` handlers as mini-updates over their page model
- server page modules may define `init(...) -> List(ToServer)` for custom SSR request selection
- server `ToServer` handlers still use constructor-derived snake_case names such as `load_games`

For normal data-backed pages, shared `init_requests` is enough. SSR can execute
it, and client init sends it when hydration data is absent. Server and client
`init` functions are optional customization hooks, and custom hooks for a route
with non-empty shared `init_requests` must call shared `init_requests`.

The generator maps those files to route constructors, URL parsing, and path builders. Dynamic path segments come from bracketed file or directory names.

```text
games/[id].gleam     -> GameDetail(id: Int)
teams/[slug].gleam   -> Team(slug: String)
```

The generated route module is Mount-specific. Each Mount owns its route root, route type, parser, path builder, and not-found representation.

## Route Kinds

Some routes are not live SPA pages, even when they live near page modules. The generator uses file suffixes to classify route behavior.

```text
.gleam            normal Mount page
.print.gleam      standalone HTML using the Mount print layout
.download.gleam   HTTP download response
.webhook.gleam    external HTTP input route
.upload.gleam     multipart upload route
```

Route kind is part of the generated route metadata. It is not a post-routing exception.

Normal page routes render through the Mount shell and may boot the client runtime.

Print routes return HTML through a print layout. They do not use the normal app shell by default. They may still use print media CSS inside the print layout, but the generated route kind gives the app a separate layout and navigation contract.

Download routes return HTTP file responses. The client router must not intercept them as live navigation targets.

Webhook routes receive external input. They can use different middleware, body parsing, authentication, CSRF, and error response rules than browser page routes.

Upload routes receive multipart input. They can use different request size limits, body parsing, and response contracts than browser page routes.

Webhook and upload modules may be server-only route modules because their request parsing and provider behavior do not compile to JavaScript. They still participate in the generated route table through their file suffix and Mount placement.

## Mount ClientSharedState

Each Mount owns a `ClientSharedState` type for shell-level state that pages need but do not keep as local page state.

Examples include:

- signed-in user email
- role or permission summary
- league name
- locale
- dark mode
- current season or selected resource
- root-level toast or flash state

The Mount boot contract is app-owned until the route generator grows explicit
runtime support for it:

- server shell encodes the Mount `ClientSharedState`
- client setup decodes the `ClientSharedState`
- page init receives the `ClientSharedState`
- page `ToClient` handlers can emit page-local effects or shell-level updates
- the root Mount view can react to shell-level updates

`ClientSharedState` is per Mount. Public and admin can shape their shared client state differently.

`ClientSharedState` is separate from SSR page data. SSR page data is a boot-time `ToClient` value for the current route. `ClientSharedState` is Mount-level state for the shell, layouts, and pages.

## Authorization Support

Authorization policy stays in app-owned handlers and domain modules. The generator does not try to declare every permission rule beside routes or commands.

Generated route code still supports authorization by making the policy path
consistent:

- request context reaches every server handler
- app dispatch can reject commands before handler delegation
- rejection can emit a Mount-appropriate `ToClient` value when the app defines one
- rejection can log an issue through app runtime logging

This keeps row-level, function-level, route-level, and role-specific permission checks in app code while keeping the transport behavior predictable.

## Cross-Mount Updates

The shared root `ToClient` graph is the live update contract. A server operation in one Mount may emit a `ToClient` value handled by another Mount when that Mount has an active handler for the constructor.

The generator does not introduce separate topic payload types. The app runtime
decides which pushed `ToClient` values go to which connected clients.

App-domain events and topic subscriptions are outside this contract.

## Extraction Boundary

The generator owns code that is derived from source files or wire-visible types in places Gleam cannot derive itself.

Generation is a good fit for:

- routes derived from page file paths
- route kind dispatch derived from file suffixes
- shared API codec graphs
- ETF encoders and decoders
- route metadata

Libraries are a better first fit for reusable behavior such as validation, form widgets, job queues, upload state machines, payment providers, CSV writers, and storage adapters.

App code owns business policy, permission checks, provider-specific behavior, and domain decisions.
