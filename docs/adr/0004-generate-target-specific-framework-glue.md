# Generate Target Specific Framework Glue

Whole modules where every import and declaration is target annotated are framework glue, not user-authored page code. Rally should generate or own those modules so user pages keep the clean shared, client, and server section shape.

Browser boot, hydration, client transport, per-page server dispatch, SSR handlers, page protocol adapters, route composition glue, and build metadata are generator-owned. User-owned modules should not be files that exist only to wrap target-specific generated plumbing.

Generated glue should also own mechanical page dispatch around routing, loads, hydration, and broadcast delivery. Moving that dispatch into a different user-authored root module is not a simplification; it only hides page behavior behind another handwritten adapter.

Generated glue should also cover the standard app conventions described in [0012: Use Convention Driven Rally App Surface](0012-use-convention-driven-rally-app-surface.md). Standard bootstrap, static serving, document boot mechanics, browser lifecycle, websocket transport, and config/env parsing are framework glue when they do not express product behavior.

Generated Rally code should be thin glue. Rally should not generate a full client app from server-shaped source. Client-side application behavior is authored in Gleam, with JS or TS reserved for tiny FFI modules around browser APIs.

Rally-generated glue must respect the library boundaries in [0009: Separate Libero Proute And Rally Roles](0009-separate-libero-proute-and-rally-roles.md). Libero owns ETF codecs and contract output. Proute owns routing and page glue. Rally composes those outputs under `src/generated/rally/**`.

Rally Scoreboard still compiles as one package for JavaScript and Erlang. Target annotations remain the mechanism for separating platform-specific code, but generated framework glue should carry most of the repetitive annotation burden.
