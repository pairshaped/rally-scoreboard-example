# Scoreboard Unified

Scoreboard Unified is the unified-source scoreboard app.

The project is testing one authored Gleam source tree that compiles for both supported targets:

```sh
gleam build --target javascript
gleam build --target erlang
```

Target-specific behavior is marked at the declaration or import boundary. Today that means Gleam's `@target(javascript)` and `@target(erlang)` syntax. The architecture depends on target-scoped declarations, not on that exact spelling.

## Shape

- `src/api/**` contains every type that may cross the wire.
- `src/public/pages/**` and `src/admin/pages/**` contain authored page modules.
- `src/public/views/**`, `src/admin/views/**`, and `src/components/**` contain reusable view code.
- `src/generated/proute/**` is generated route and page glue.
- `src/generated/sql/**` is generated typed SQL for Erlang-only server paths.
- `src/generated/api/**` will contain generated ETF codecs and target-annotated browser/server API transport glue for `src/api/**`.

Generated source is checked in while this project proves the shape. That includes tracer generated code used before full generator coverage exists.

## Wire Boundary

Only public types under `src/api/**` are wire-visible.

The root message types are:

- `api/to_server.ToServer`: browser-to-server commands
- `api/to_client.ToClient`: server-to-browser results, boot data, and live events

Domain models that cross the wire also live under `src/api/domain/**`. Page models, page messages, route types, SQL row types, handler-local types, and view helper types do not cross the wire.

## Current Commands

From the repository root:

```sh
gleam run -m marmot migrate
gleam run -m marmot
gleam run -m proute
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

The main design note is [docs/unified-target-source.md](/Users/daverapin/projects/gleam/scoreboard-unified/docs/unified-target-source.md).

The architecture decision is [ADR 0009: Use Target Annotations For Unified Source](/Users/daverapin/projects/gleam/scoreboard-unified/docs/adr/0009-use-target-annotations-for-unified-source.md).
