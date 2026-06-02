# Unified Target Source

Scoreboard Unified uses one authored Gleam source tree. The source tree compiles directly for JavaScript and Erlang, with target-specific declarations and imports marked where target-specific behavior starts.

```text
src/
  api/
  public/
  admin/
  components/
  generated/
```

The target builds are the compatibility oracle:

```sh
gleam build --target javascript
gleam build --target erlang
```

## Working Thesis

The root app compiles directly for both targets. Browser-only code uses JavaScript target annotations. Server-only code uses Erlang target annotations. Shared code stays unannotated and must compile on both targets.

Current Gleam uses:

```gleam
@target(javascript)
pub fn browser_update(...) {
  Nil
}

@target(erlang)
pub fn server_handler(...) {
  Nil
}
```

The architecture depends on target-scoped declarations and imports. The exact syntax can follow Gleam as it evolves.

## Source Layout

The unified source tree is the user-owned package:

```text
src/api/to_server.gleam
src/api/to_client.gleam
src/api/domain/**/*.gleam

src/public/pages/**/*.gleam
src/public/views/**/*.gleam
src/public/client_shared_state.gleam

src/admin/pages/**/*.gleam
src/admin/views/**/*.gleam
src/admin/client_shared_state.gleam

src/components/**/*.gleam
src/sql/**/*.sql

src/generated/sql/**/*.gleam
src/generated/proute/**/*.gleam
src/generated/api/**/*.gleam
```

Generated source is checked in while this project proves the shape. Tracer generated modules are acceptable when they prove the target boundary before full generator coverage exists.

Each generator owns a namespace under `src/generated`:

- `generated/sql`: typed SQL modules from Marmot, Erlang-only when they touch SQLite
- `generated/proute`: route and page glue from Proute
- `generated/api`: ETF codecs, generated result error types, and browser/server transport glue generated around `ToServer`, `ToClient`, and load/save results

## Wire Contract

Only `src/api/**` defines user-authored types that cross the wire. Libero may
also generate protocol helper types under `src/generated/api/**`.

That rule is intentionally strict. Types from pages, views, SQL modules, generated routes, runtime helpers, and server handlers do not cross the wire. If a user-authored app or domain value crosses the transport boundary, its type belongs under `src/api`.

The root protocol stays app-level and globally unique:

```gleam
pub type ToServer {
  LoadGames
  UpdateScore(game_id: Int, home_score: Int, away_score: Int, period: String)
}

pub type ToClient {
  GamesLoaded(games: List(PublicGameSummary))
  GameUpdated(game: GameSnapshot)
}
```

Domain models that cross the wire live under `src/api/domain/**`.

Libero generates the load/save result error types under `src/generated/api/result.gleam`.

The ETF codec graph is:

```text
src/api/**/*.gleam
```

Constructor names inside that graph must be unique plain ETF atoms. Module paths, type names, transport direction, and Mount names do not create runtime identity.

## Target Boundary Rule

Annotate the import and declaration where target-specific behavior starts.

Examples:

```gleam
@target(javascript)
import generated/api/client as api_client

@target(javascript)
pub fn update(model: Model, msg: Message) -> Model {
  case msg {
    AdjustHome(game_id, home_score, away_score, period) -> {
      api_client.send(to_server.UpdateScore(
        game_id:,
        home_score:,
        away_score:,
        period:,
      ))
      model
    }
  }
}
```

```gleam
@target(erlang)
import generated/sql/games_sql

@target(erlang)
pub fn update_score(...) -> DispatchReply {
  panic as "implemented by the app"
}
```

The compiler should catch wrong-target leaks:

- JavaScript-kept code cannot call Erlang-only declarations.
- Erlang-kept code cannot call JavaScript-only declarations.
- Target-specific imports should be annotated so inactive-target builds do not retain useless or invalid imports.

The practical authoring rule:

> Put the target annotation at the first declaration or import that depends on a target-specific capability.

## Page Shape

A page module may own:

- page `Model`
- browser-originated page `Message`
- target-neutral `view`
- shared boot request declarations
- JavaScript-only update paths
- Erlang-only server handlers
- constructor-named `ToClient` handlers where the client applies app data

Local page messages do not cross the wire. They represent browser-originated events such as clicks, input changes, timers, subscriptions, and JavaScript callbacks.

Server app data crosses the wire as `ToClient`. No-data load and save results cross
the wire as `Result(Nil, List(ApiLoadError))` or
`Result(Nil, List(ApiSaveError))`.

Browser commands cross the wire as `ToServer`.

## Generated API Shape

The first tracer should use checked-in generated modules:

```text
src/generated/api/to_server_codec.gleam
src/generated/api/to_client_codec.gleam
src/generated/api/result.gleam
src/generated/api/client.gleam
src/generated/api/server.gleam
```

The codec modules exercise the real `api` types before ETF is fully implemented.

The API transport modules are target annotated:

- browser transport accepts `ToServer`, encodes it, and sends it
- server transport decodes `ToServer`, dispatches to server handlers, and emits a result plus any `ToClient` app data
- transport details stay inside generated modules

The tracer should demonstrate the whole intended flow:

```text
browser page Message
  -> ToServer
  -> generated/api/client
  -> generated/api/to_server_codec
  -> generated/api/server
  -> server handler
  -> load/save result
  -> optional ToClient app data
  -> generated/api/to_client_codec
  -> generated/api/client receive path
  -> page ToClient handler
  -> updated page Model
```

The tracer implementation can be inert, but the types and target boundaries should be real.

## SQL And Marmot

Marmot output belongs under root `src/generated/sql`.

The authored root contains SQL files:

```text
src/sql/**/*.sql
```

Marmot writes:

```text
src/generated/sql/games_sql.gleam
src/generated/sql/standings_sql.gleam
src/generated/sql/teams_sql.gleam
```

Server code imports these modules from Erlang-only declarations. JavaScript builds must not keep code paths that import SQL modules.

Raw `.sql` files are generator inputs. They are not runtime source.

## Proute

Proute generation stays separate from transport and codec generation.

Proute writes route and page glue under:

```text
src/generated/proute
```

Each Mount gets a small generated group:

```text
src/generated/proute/public/routes.gleam
src/generated/proute/public/page_input.gleam
src/generated/proute/public/pages.gleam

src/generated/proute/admin/routes.gleam
src/generated/proute/admin/page_input.gleam
src/generated/proute/admin/pages.gleam
```

Root source imports Proute through stable generated modules:

```gleam
import generated/proute/public/routes as public_routes
import generated/proute/admin/routes as admin_routes
```

## Validation

The architecture is only convincing if the same package passes both target builds:

```sh
gleam run -m proute
gleam check
gleam build --target javascript
gleam build --target erlang
```

For the tracer, both target builds must pass with generated API codec and transport modules checked in.

## Summary

The useful design is:

> Write one Gleam app. Keep user-authored wire types under `api`. Put generated protocol helpers under `src/generated/api`. Put target facts on target-specific declarations and imports. Let Gleam target builds catch cross-target mistakes.

That keeps the hard boundary where the compiler can help, and it leaves generation focused on API codecs, route glue, transport glue, and clear diagnostics around the `api` wire graph.
