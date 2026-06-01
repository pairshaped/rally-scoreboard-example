# Use Target Annotations For Unified Source

Scoreboard Unified uses one authored Gleam source tree that compiles for JavaScript and Erlang.

Target-specific behavior is expressed with target annotations on declarations and imports. Generated support modules live under `src/generated`.

## Decision

The root package is the source of truth:

```text
src/api/**
src/public/**
src/admin/**
src/components/**
src/generated/**
```

The package must compile for both targets:

```sh
gleam build --target javascript
gleam build --target erlang
```

Gleam's current spelling is `@target(javascript)` and `@target(erlang)`. The architecture depends on target-scoped declarations and imports, not on that exact syntax.

Generated support code is checked in under `src/generated`:

```text
src/generated/sql/**
src/generated/proute/**
src/generated/api/**
```

Generated modules use the same target annotation rules as user-authored modules.

## Wire Boundary

Only public types under `src/api/**` may cross the wire.

The API roots are:

- `api/to_server.ToServer`: browser-to-server commands
- `api/to_client.ToClient`: server-to-browser results, boot data, and live events
- `api/domain/**`: domain models that cross the wire

Types outside `src/api/**` are not wire-visible. This includes page models, page messages, route types, SQL row types, handler-local types, view input types, and generated runtime helper types.

Codec generation walks the `src/api/**` graph and enforces one global plain ETF constructor namespace.

## Target Boundaries

Target annotations belong where target-specific behavior begins:

- JavaScript-only imports and declarations for browser APIs, DOM effects, browser storage, and browser transport setup
- Erlang-only imports and declarations for SQL, secrets, filesystem access, server runtime APIs, and server handlers
- unannotated declarations only when they compile and make sense on both targets

Target-specific imports should be annotated too. An inactive declaration with an active import can still create warnings or invalid target output.

## Generated Modules

Generated support modules cover the pieces Gleam does not derive:

- ETF codecs for `ToServer`, `ToClient`, and `api/domain/**`
- browser API transport glue around sending `ToServer`
- server API transport glue around decoding `ToServer`, dispatching handlers, and emitting `ToClient`
- route and page glue from file routes
- SQL modules from SQL files

The generated API modules are part of the same root package. Their target annotations decide which declarations are visible to each target build.

## Page Contract

Page modules are authored once under their Mount:

```text
src/public/pages/**/*.gleam
src/admin/pages/**/*.gleam
```

A page module may contain target-neutral model and view code, JavaScript-only browser update code, and Erlang-only server handler code.

Local page messages do not cross the wire. Browser commands cross as `ToServer`. Server outcomes and live events cross as `ToClient`.

## Rules

1. There is one authored root source tree.
2. The root source tree must compile for JavaScript and Erlang.
3. Target-specific declarations and imports carry target annotations.
4. Shared declarations are unannotated only when they compile for both targets.
5. Generated support code lives under `src/generated`.
6. Generated support code is checked in for this project.
7. Only public types under `src/api/**` cross the wire.
8. `ToServer` and `ToClient` are the root transport types.
9. Domain types that cross the wire live under `src/api/domain/**`.
10. Types outside `src/api/**` do not cross the wire.
11. Codec generation validates the `src/api/**` graph.
