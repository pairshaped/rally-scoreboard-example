# Use Convention Driven Rally App Surface

Rally applications should use strong framework conventions for the standard app
shape. The authored application describes product meaning, while Rally owns
repeated bootstrap, transport, routing shell, document boot, and runtime
mechanics.

The app-owned surface is:

- DB schema, migrations, seeds, authored SQL, and page data mapping.
- Layout, shell UI, page views, page UI state, and page update behavior.
- Page load/save behavior and the domain rules inside those handlers.
- Auth policy callbacks: user lookup, role checks, provider-specific product
  policy, and route narrowing where the product cares.
- Broadcast topics, broadcast events, broadcast payload data, and page interest
  in those events.
- Page-level interpretation of route params when those params have domain
  meaning.
- Mount-owned page shared-state types that expose page-visible product facts,
  such as authenticated user data, authorization facts, and feature flags.

Rally owns the standard framework surface around that app code:

- App/package identity from `gleam.toml`.
- Process bootstrap for the standard template app.
- `PORT` override handling, parsing, fallback, and wiring into the HTTP
  listener.
- DB path config from `gleam.toml` with environment override, DB opening, and
  request/server context construction.
- Auth session secret config and generic session runtime mechanics.
- Static asset serving conventions such as `/assets` and `priv/static`.
- HTTP routing shell, public/admin mount dispatch, and default fallback
  behavior.
- SSR document boot mechanics, hydration attributes, boot data encoding,
  browser entrypoint selection, and query-param extraction.
- Browser lifecycle ceremony: mount startup, current-path boot, page effect
  wiring, server-frame handling, navigation effects, browser navigation
  listeners, dark-mode runtime effects, and topic sync.
- Standard page data load effects, hydration application, and load-result
  mapping into page `Loaded` messages.
- Browser shell state creation and update. Shell state covers active path, dark
  mode, toast state, boot mechanics, and other mount/runtime concerns.
- Websocket transport ceremony: upgrade handler shape, per-connection state
  threading, topic selector setup, topic joins/leaves, custom-frame forwarding,
  load/save dispatch, request/result encoding, and broadcast delivery.
- Generated Rally glue that consumes Proute's generated routes and pages for
  browser lifecycle, hydration, transport, load/save wiring, SSR composition,
  and websocket plumbing.

Proute owns route discovery, route params, query params, generated page enums,
and route-to-page construction. Page shared state is passed to generated page
hooks by convention 100 percent of the time. Scoreboard uses one mount-owned
type per mount:

- `admin/page_shared_state.AdminPageSharedState`
- `public/page_shared_state.PublicPageSharedState`

There is no separate `PageContext` adapter layer. Browser mounts build the
page-visible shared state from boot facts. SSR builds the same page-visible
shared state from request-derived facts. Pages receive that shared state
directly, along with generated route params and query params.

Pages expose `initial_model` as their normal starting point. `init` is optional
and reserved for page-specific client startup effects such as browser APIs,
local storage, focus, measurement, or one-off DOM effects. Standard page data
loading belongs to Rally-generated glue.

Rally should not pass browser shell state into pages. If a page needs a
shell-derived product fact, the app exposes that fact through the mount page
shared-state type deliberately. This keeps page-visible product facts separate
from mount/runtime mechanics.

Topic sync follows
[0010: Separate Mutation Results From Broadcast Events](0010-separate-mutation-results-from-broadcast-events.md).
App code declares typed topics and topic keys. Rally-generated glue maps those
values to the text control frames used to keep each websocket connection's
server-side topic set current. Rally owns the sync mechanics; the app owns the
topic vocabulary and meaning.

Dynamic route params stay strings at the generated routing boundary. URLs are
strings, and typed params such as integers, UUIDs, or slugs need explicit
product semantics. Rally and Proute should not infer those semantics from names
such as `id_`. Pages parse route params when a domain-specific type is needed.

Generated page state retains route params for dynamic pages. Route-derived
hooks such as page topics may accept route params and the current model,
following the Elm Land-style page construction idea that route context belongs
to the page. Page models should not need to carry route identity solely to make
framework lifecycle hooks work.

Elm Land keeps generated app state beside the current page model, replaces the
current page model on navigation, and passes route information into shared
initialization, update, and subscriptions. Rally should stay close to that shape
where it fits Gleam and the unified client/server source tree, with Proute
owning route-driven page construction and Rally owning runtime lifecycle.

An authored root module is acceptable only when it expresses a product decision.
If the code would be copied almost unchanged into another Rally template app, it
belongs in Rally runtime or generated Rally glue.

Rally should prefer intelligent defaults over app configuration. Configuration
should exist only for values the app or deployment actually chooses. The
standard case should require little or no authored bootstrap code.

This follows the framework shape used by Rails: conventions remove decisions
users do not care about, while keeping app behavior explicit where the product
has meaning.
