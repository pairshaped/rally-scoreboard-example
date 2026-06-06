# Rally Scoreboard

Rally Scoreboard is the definitive Rally example app.

The project illustrates how Rally, Proute, Libero, and Marmot can be used to create a client and server from one source tree.

```sh
gleam build --target javascript
gleam build --target erlang
```

Target-specific behavior is marked at the declaration or import boundary. Today that means Gleam's `@target(javascript)` and `@target(erlang)` syntax. The architecture depends on target-scoped declarations, not on that exact spelling.

Rally should not generate a full client app from server-shaped source. Rally-generated code is limited to thin route, wire, hydration, SSR, boot, transport, server dispatch, build metadata, and Libero codec composition glue.

## Shape

- `src/public/pages/**` and `src/admin/pages/**` contain authored page modules.
- `src/components/**` contains reusable view code.
- `src/generated/proute/**` is generated route and page glue.
- `src/generated/rally/**` is generated page protocol, SSR, hydration, browser boot, client transport, and server dispatch glue.
- `src/generated/sql/**` is generated typed SQL for Erlang-only server paths.

Authored SQL lives beside the page or workflow that owns it, in a local `sql/` directory. Generated SQL stays under `src/generated/sql/**`.

Generated source is checked in while this project proves the shape. That includes tracer generated code used before full generator coverage exists.

## Page Contract

Pages own their local `Model`, browser `Msg`, page-local `ServerMsg`, pure `initial_model`, shared `view`, browser `update`, optional `init`, and Erlang-only `load` and `handle_save` functions. Most pages omit `init`; use it only for page-specific browser startup effects such as browser APIs, local storage, focus, measurement, or one-off DOM effects.

Page data shapes belong to the page that renders and updates them. Shared types are reserved for stable app concepts independent of a page.

Wire-crossing types may reference page-local types, approved root wire types under `src/wire/**`, primitives, and containers. Helper, service, query, business, formatting, and display types can be used as behavior, but their owned shapes cannot cross the wire.

Client-side application behavior is authored in Gleam. JS or TS is reserved for tiny FFI modules around browser APIs.

Generated output and rewritten source should preserve the Rally/Gleam house style: stable section layout for large modules and grouped, sorted imports.

## Current Commands

From the repository root:

```sh
gleam run -m marmot migrate
gleam run -m marmot seed
gleam run -m marmot
gleam run -m proute
gleam run -m rally load-rpc
gleam check
gleam build --target javascript
gleam build --target erlang
```

## Public Routes

- `/`
- `/games`
- `/games?team=TOR`
- `/games/:id`
- `/sign_in`
- `/standings`
- `/teams/:slug`

Public routes are generated from `src/public/pages`.

## Admin Routes

- `/admin`
- `/admin/games`

Admin routes are generated from `src/admin/pages`.

## Design Notes

The main design note is [docs/unified-target-source.md](docs/unified-target-source.md).

Local ADRs cover example-owned choices such as page data ownership and SQL ownership. Rally framework ADRs live in the Rally repository.
