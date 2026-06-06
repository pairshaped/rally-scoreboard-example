# Unified Target Source

Rally Scoreboard uses one authored Gleam source tree. The source tree compiles directly for JavaScript and Erlang, with target-specific declarations and imports marked where target-specific behavior starts. Rally should not generate a separate client package from server-shaped source.

```text
src/
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

## Page Shape

A page module should read like a basic TEA SPA page with server handlers at the bottom.

```gleam
import components/ui
import generated/proute/public/page_input
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import public/page_shared_state.{type PublicPageSharedState}
import rally/runtime/load as runtime_load

@target(erlang)
import generated/sql/games_sql

@target(javascript)
import rally/server

pub type Model {
  Model(games: List(Game), saving: Bool)
}

pub type Msg {
  AdjustHome(id: Int, delta: Int)
  Loaded(Result(List(Game), runtime_load.LoadError))
  Saved(Result(Game, SaveError))
}

pub type ServerMsg {
  ServerAdjustHome(id: Int, delta: Int)
}

pub fn view(model: Model) -> Element(Msg) {
  todo
}

// INIT

/// generated/proute/public/pages module calls this to construct an empty page
/// before Rally applies hydrated or freshly loaded data.
pub fn initial_model(
  _page_shared_state: PublicPageSharedState,
  _query_params: page_input.QueryParams,
) -> Model {
  Model(games: [], saving: False)
}

/// generated/proute/public/pages module calls this when the route first builds
/// the page.
/// Most Rally pages omit this. Use it only for page-specific client startup
/// effects such as browser APIs, local storage, focus, measurement, or one-off
/// DOM effects. Standard page data loading is owned by generated Rally glue.
pub fn init(
  page_shared_state page_shared_state: PublicPageSharedState,
  query_params query_params: page_input.QueryParams,
) -> #(Model, Effect(Msg)) {
  #(initial_model(page_shared_state, query_params), effect.none())
}

// CLIENT

@target(javascript)
pub fn update(msg: Msg, model: Model) -> #(Model, Effect(Msg)) {
  case msg {
    AdjustHome(id, delta) -> #(
      Model(..model, saving: True),
      server.send(
        ServerAdjustHome(id:, delta:),
        on_result: fn(result) { Saved(result) },
      ),
    )
    Loaded(_) | Saved(_) -> todo
  }
}

// SERVER

@target(erlang)
pub fn load(ctx, params) -> Result(List(Game), runtime_load.LoadError) {
  todo
}

@target(erlang)
pub fn handle_save(ctx, msg: ServerMsg) -> Result(Game, SaveError) {
  todo
}
```

Shared imports come first, followed by Erlang-targeted imports, then JavaScript-targeted imports. The module body follows the same target grouping when practical: shared declarations first, then init/shared declarations, then server/client sections for target-specific behavior.

The section comments are for humans. Rally validates the page contract by function names, signatures, target availability, and wire-visible types.

`initial_model` is the normal starting point for a page. `init` is optional. A page should define `init` only when it needs page-local browser startup work that cannot be represented as loaded page data or normal update behavior. Rally-generated browser glue calls `init` when it exists; otherwise it constructs the page with `initial_model` and no effect. Rally-generated SSR glue uses `initial_model` so server rendering never depends on browser-only effects.

## API/RPC Effects

Page code sends page-local `ServerMsg` values through a Rally API/RPC effect:

```gleam
server.send(ServerSave(form), on_result: Saved)
```

The effect returns Lustre `Effect(Msg)`. Rally owns request id generation, pending callback registration, wire encoding, result decoding, and dispatching the selected local `Msg`.

`on_result` receives a normal `Result(success, error)` and returns a local browser `Msg`. A save with no success payload uses `Result(Nil, SaveError)`. A create flow can use `Result(Item, SaveError)`.

Page code carries local context in the completion message only when it needs that context:

```gleam
server.send(
  ServerUpdateScore(game_id:, home_score:, away_score:),
  on_result: fn(result) { ScoreSaved(game_id, result) },
)
```

Server-originated state events should be delivered to other subscribed clients, excluding the connection that initiated the mutation. Request results manage request lifecycle for the initiating page. Broadcast events carry server-authoritative state for subscribed peers.

Generated load/save transport helpers are internal Rally glue. Authored page code uses `server.send(ServerMsg, on_result: ...)` for page-local server commands, while generated Rally browser glue owns standard page data loading.

## Authoring Style

Use the existing Rally/Gleam house style for module layout. Large modules use section comment headers to separate major regions:

```text
// TYPES
// INIT
// UPDATE
// BROADCAST
// VIEW
// EFFECTS
// HELPERS
```

Small modules do not need headers when headers add noise.

Imports are grouped by target first:

1. unannotated imports that compile on both targets
2. `@target(erlang)` imports
3. `@target(javascript)` imports

Groups are separated by a blank line. Within each target group, imports are sorted alphabetically.

Generated output and rewritten source should preserve this order and style where `gleam format` allows it. The formatter owns final import formatting and preserves blank-line groups. Rally should not fight the formatter, emit random import order, or churn section layout when semantics did not change.

## Page Data

Page data shapes belong to the page that renders and updates them. A list page, detail page, and form page should duplicate similar fields instead of sharing one model just because their current shapes overlap.

Shared types are reserved for stable app concepts independent of a page, such as identifiers, enums, or value objects. Page payloads, form models, table rows, detail data, and save responses stay page local.

The approved root wire namespace is `src/wire/**`. Wire-visible page protocols may reference page-local types, `src/wire/**` types, primitives, and standard containers. They may not reference helper, service, query, business, formatting, or display types, even transitively.

Helpers are still allowed as behavior. A page may call helpers and services, but their owned shapes cannot become wire contract shapes.

## Generated Source

Generated source lives under `src/generated`:

```text
src/generated/proute/**/*.gleam
src/generated/rally/**/*.gleam
src/generated/sql/**/*.gleam
```

Proute owns file routes, page enums, route params, query params, and page dispatch shape. Rally consumes Proute output and generates page protocol code, browser boot, hydration, SSR, client transport, and server dispatch. Marmot writes typed SQL modules for Erlang-only server paths.

Generated modules use the same target annotation rules as user-authored modules.

Rally-generated code should be thin glue: codecs, route glue, wire transport, hydration, SSR, browser boot, server dispatch, and build metadata. Rally should not generate a full client app. Client-side application behavior is authored in Gleam, with JS or TS limited to tiny FFI modules for browser APIs.

## Target Boundaries

Target annotations belong where target-specific behavior begins:

- JavaScript-only imports and declarations for browser APIs, DOM effects, browser storage, and browser transport setup
- Erlang-only imports and declarations for SQL, secrets, filesystem access, server runtime APIs, and server handlers
- unannotated declarations only when they compile and make sense on both targets

Target-specific imports should be annotated too. Inactive-target builds should not retain useless or invalid imports.

Boundary diagnostics should name the violated contract, the page/action/channel, the offending type or import, the path that made it reachable, and the smallest likely fix.

## Routing And Decoding

Proute owns URL routing and page identity. Rally consumes Proute's page, action, or channel identity when dispatching incoming wire messages, and decodes page-local payloads only after that destination is known. This keeps page-local type names local: two pages can both define `Item` without needing global type identity hashes.

## SQL And Marmot

Marmot output belongs under root `src/generated/sql`.

Authored SQL files live beside the page or workflow that owns the server behavior, in a local `sql/` directory:

```text
src/public/pages/items.gleam
src/public/pages/items/sql/list_items.sql

src/public/pages/items/id_.gleam
src/public/pages/items/id_/sql/get_item.sql
```

Workflow modules follow the same rule: the workflow owns its SQL locally, and generated SQL still goes to `src/generated/sql`.

Server code imports these modules from Erlang-only declarations. JavaScript builds must not keep code paths that import SQL modules.

## Stop Conditions

The chase should stop and revisit the design if target annotations cannot escape generated-client-package assumptions, page-local decoding still needs global type identity hashes, boundary checking requires brittle whole-program magic, JS or TS grows beyond tiny browser API FFI shims, generated client code starts to look like an app, Rally cannot produce humane boundary diagnostics, or authored SQL colocation makes Marmot output unstable or hard to import.
