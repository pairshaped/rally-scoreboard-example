# Use Convention Driven Rally App Surface

Rally applications should use strong framework conventions for the standard app shape. The authored application should describe product meaning, while Rally owns repeated bootstrap, transport, routing shell, document boot, and runtime mechanics.

The app-owned surface is:

- DB schema, migrations, seeds, authored SQL, and page data mapping.
- Layout, shell UI, page views, page UI state, and page update behavior.
- Page load/save behavior and the domain rules inside those handlers.
- Auth policy callbacks: user lookup, role checks, provider-specific product policy, and route narrowing where the product cares.
- Broadcast topics, broadcast events, broadcast payload data, and page interest in those events.

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
- Websocket transport ceremony: upgrade handler shape, per-connection state threading, topic selector setup, topic joins/leaves, custom-frame forwarding, load/save dispatch, request/result encoding, and broadcast delivery.
- Generated route/page dispatch by consuming Proute output.

An authored root module is acceptable only when it expresses a product decision. If the code would be copied almost unchanged into another Rally template app, it belongs in Rally runtime or generated Rally glue.

Rally should prefer intelligent defaults over app configuration. Configuration should exist only for values the app or deployment actually chooses. The standard case should require little or no authored bootstrap code.

This follows the framework shape used by Rails: conventions remove decisions users do not care about, while keeping app behavior explicit where the product has meaning.
