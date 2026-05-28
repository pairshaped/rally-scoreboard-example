# Use File Routes, Route Kinds, And Mount Contexts

The Generator Framework derives Mount routes from route modules. App authors add, move, and name modules; the Generator Framework emits the route type, URL parser, path builder, server dispatch, client router, and navigation helpers.

The generated routing contract follows an Elm Land style convention: the file path is the route declaration.

## File Routes

Normal page modules use the `.gleam` suffix and are mounted through the Mount shell. They usually live in the shared Mount page tree so the view code can compile for both targets.

```text
shared/src/shared/public/pages/games.gleam
shared/src/shared/public/pages/games/[id].gleam
shared/src/shared/public/pages/teams/[slug].gleam
shared/src/shared/admin/pages/games.gleam
```

The Generator Framework maps those files to route constructors, URL parsing, and path builders. Dynamic path segments come from bracketed file or directory names.

```text
games/[id].gleam     -> GameDetail(id: Int)
teams/[slug].gleam   -> Team(slug: String)
```

The generated route module is Mount-specific. Each Mount owns its route root, route type, parser, path builder, and not-found representation.

## Route Kinds

Some routes are not live SPA pages, even when they live near page modules. The Generator Framework uses file suffixes to classify route behavior.

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

## Mount Client Contexts

Each Mount owns a client context type for shell-level state that pages need but should not keep as local page state.

Examples include:

- signed-in user email
- role or permission summary
- league name
- locale
- dark mode
- current season or selected resource
- root-level toast or flash state

The Generator Framework emits the Mount boot contract:

- server shell encodes the Mount client context
- client setup decodes the context
- page init receives the context
- page receivers can emit shell-level updates
- the root Mount view can react to shell-level updates

The context type is per Mount. Public and admin can shape their client contexts differently.

## Authorization Support

Authorization policy stays in app-owned handlers and domain modules. The Generator Framework does not try to declare every permission rule beside routes or commands.

Generated code still supports authorization by making the policy path consistent:

- request context reaches every server handler
- Mount backend dispatch can reject commands before handler delegation
- generated dispatch rejects commands that belong to another Mount
- rejection returns the backend model unchanged
- rejection can emit a Mount-appropriate `ToClient` value when the app defines one
- rejection can log an issue through generated runtime logging

This keeps row-level, function-level, route-level, and role-specific permission checks in app code while keeping the transport behavior predictable.

## Cross-Mount Updates

The shared root `ToClient` graph remains the live update contract. A server operation in one Mount may emit a `ToClient` value received by another Mount when that Mount has an active receiver for the constructor.

The Generator Framework does not introduce separate topic payload types yet. Receiver presence is still the client-side interest signal.

If the shared `ToClient` graph becomes too broad for larger apps, a later design can add app-domain events and topic subscriptions behind the generated Mount receiver layer.

## Extraction Boundary

The Generator Framework should own code that is derived from source files or wire-visible types in places Gleam cannot derive itself.

Generation is a good fit for:

- routes derived from page file paths
- route kind dispatch derived from file suffixes
- shared API codec graphs
- transport encoders and decoders
- client and server dispatch tables
- Mount boot contracts
- request context plumbing

Libraries are a better first fit for reusable behavior such as validation, form widgets, job queues, upload state machines, payment providers, CSV writers, and storage adapters.

App code owns business policy, permission checks, provider-specific behavior, and domain decisions.
