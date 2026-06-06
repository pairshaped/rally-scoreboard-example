# Use Convention Driven Rally App Surface

Rally applications should use strong framework conventions for the standard app shape. The authored application should describe product meaning, while Rally owns repeated bootstrap, transport, routing shell, document boot, and runtime mechanics.

The app-owned surface is:

- DB schema, migrations, seeds, authored SQL, and page data mapping.
- Layout, shell UI, page views, page UI state, and page update behavior.
- Page load/save behavior and the domain rules inside those handlers.
- Auth policy callbacks: user lookup, role checks, provider-specific product policy, and route narrowing where the product cares.
- Broadcast topics, broadcast events, broadcast payload data, and page interest in those events.
- Page-level interpretation of route params when those params have domain meaning.

Rally owns the standard framework surface around that app code:

- App/package identity from `gleam.toml`.
- Process bootstrap for the standard template app.
- `PORT` override handling, parsing, fallback, and wiring into the HTTP listener.
- DB path config from `gleam.toml` with environment override, DB opening, and request/server context construction.
- Auth session secret config and generic session runtime mechanics.
- Static asset serving conventions such as `/assets` and `priv/static`.
- HTTP routing shell, public/admin mount dispatch, and default fallback behavior.
- SSR document boot mechanics, hydration attributes, boot data encoding, browser entrypoint selection, and query-param extraction.
- Browser lifecycle ceremony: mount startup, current-path boot, page effect wiring, server-frame handling, navigation effects, browser navigation listeners, dark-mode runtime effects, and topic sync.
- Browser shared-state to page-context adaptation. The app may define client shared state for shell concerns such as active path, dark mode, boot auth, or mount-specific shell data. Rally owns when that shared state is created and updated, then calls an app-provided adapter to derive `PageContext` for page init and update.
- Websocket transport ceremony: upgrade handler shape, per-connection state threading, topic selector setup, topic joins/leaves, custom-frame forwarding, load/save dispatch, request/result encoding, and broadcast delivery.
- Generated route/page dispatch by consuming Proute output.
- Generated page route context retention for dynamic routes, so route-backed page hooks can use route params without pushing that state into unrelated app shared state.

Topic sync follows [0010: Separate Mutation Results From Broadcast Events](0010-separate-mutation-results-from-broadcast-events.md). App code declares typed topics and topic keys. Rally-generated glue maps those values to the text control frames used to keep each websocket connection's server-side topic set current. Rally owns the sync mechanics; the app owns the topic vocabulary and meaning.

Dynamic route params stay strings at the generated routing boundary. URLs are strings, and typed params such as integers, UUIDs, or slugs need explicit product semantics. Rally and Proute should not infer those semantics from names such as `id_`. Pages parse route params when a domain-specific type is needed.

Generated page state retains route params for dynamic pages. Route-derived hooks such as page topics may accept route params and the current model, following the Elm Land-style page construction idea that route context belongs to the page. Page models should not need to carry route identity solely to make framework lifecycle hooks work.

Elm Land keeps generated app state as shared state beside the current page model, replaces the current page model on navigation, and passes route information into shared initialization, update, and subscriptions. Its pages and layouts can opt into `Shared.Model` and `Route` through their constructors. Rally should stay close to that shape where it fits Gleam and the unified client/server source tree.

Rally should distinguish browser shell state from page-visible shared app state. Browser shell state covers active path, dark mode, toast state, boot mechanics, and other mount/runtime concerns. Page-visible shared state covers app facts pages may intentionally depend on, such as authenticated user data, authorization facts, feature flags, or other shared product context. The existing `ClientSharedState` name was chosen to avoid confusing client state with server context or session state, but the model should not become a bag for both shell internals and page-facing app state.

The current `PageContext` adapter is a small compatibility slice: generated Rally browser mounts keep `shared_state` beside the generated page enum, parse the current route before initialization, update shared state with the canonical route path on navigation, derive `PageContext` from the latest shared state, and pass that context into page load and page update dispatch. The intended direction is closer to Elm Land: once shell state and page-visible shared state are split, page construction should be able to pass page-visible shared state directly to pages that opt into it.

The Elm Land-inspired page-construction responsibility may belong in Proute rather than Rally. Proute owns route discovery, route params, query params, generated page enums, and route-to-page dispatch. Rally should consume those outputs for browser lifecycle, hydration, transport, load/save wiring, and SSR composition. If route-aware page construction grows beyond thin consumption of Proute modules, the API should move toward Proute ownership instead of making Rally a second routing framework.

Rally should not pass the whole mount shared-state record into every page. Pages already receive the app-owned `PageContext`, route params, query params, and their own model. If a page needs shell-shared information, the app should expose that information through `PageContext` deliberately. SSR still passes request-built `PageContext` directly because server rendering already has request context and does not use browser shell shared state.

An authored root module is acceptable only when it expresses a product decision. If the code would be copied almost unchanged into another Rally template app, it belongs in Rally runtime or generated Rally glue.

Rally should prefer intelligent defaults over app configuration. Configuration should exist only for values the app or deployment actually chooses. The standard case should require little or no authored bootstrap code.

This follows the framework shape used by Rails: conventions remove decisions users do not care about, while keeping app behavior explicit where the product has meaning.
