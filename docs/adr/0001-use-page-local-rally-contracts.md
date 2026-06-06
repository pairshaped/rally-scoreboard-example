# Use Page Local Rally Contracts

Scoreboard Unified is the chase target for the next Rally page model: one root Gleam package, no generated client app, and page modules that look like ordinary TEA SPA pages with server handlers added at the bottom. Page modules own their local `Model`, browser `Msg`, page-local `ServerMsg`, pure `initial_model`, shared `view`, browser `update`, optional `init`, and Erlang-only `load` and `handle` functions.

Page modules are also the author-facing routing surface. The page filename and path decide the route. Authored page code should not match generated route constructors, parse route params from strings, or wrap itself in generated page enums. Route params arrive through the generated page input shape, and generated Proute/Rally glue owns route dispatch around the page.

The source model is one authored `src/` tree with target annotations, not separate generated client and server packages.

The default page shape is:

```gleam
import components/ui
import generated/proute/public/page_input
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import public/page_shared_state.{type PublicPageSharedState}

@target(erlang)
import generated/sql/games_sql

@target(javascript)
import rally/server

pub type Model {
  Model(games: List(Game), saving: Bool)
}

pub type Msg {
  AdjustHome(id: Int, delta: Int)
  Loaded(Result(List(Game), LoadError))
  Saved(Result(Game, SaveError))
}

pub type ServerMsg {
  ServerAdjustHome(id: Int, delta: Int)
}

pub fn view(model: Model) -> Element(Msg) {
  todo
}

// INIT

/// Pure starting state for this page.
/// Generated Rally browser and SSR glue layer hydrated or freshly loaded data
/// onto this model.
pub fn initial_model(
  _page_shared_state: PublicPageSharedState,
  _query_params: page_input.QueryParams,
) -> Model {
  Model(games: [], saving: False)
}

/// Optional Proute page init hook.
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
pub fn load(ctx, params) -> Result(List(Game), LoadError) {
  todo
}

@target(erlang)
pub fn handle(ctx, msg: ServerMsg) -> Result(Game, SaveError) {
  todo
}
```

Shared declarations appear before `// SERVER` and `// CLIENT`. Erlang declarations appear under `// SERVER`. JavaScript declarations appear under `// CLIENT`. Imports follow the house style from ADR 0007: shared imports first, then Erlang-targeted imports, then JavaScript-targeted imports. The section comments are a human convention; Rally should validate function names, signatures, target availability, and wire-visible types, not rely on comments.

`initial_model` is the normal starting point for a page. `init` is optional. A page should define `init` only when it needs page-local browser startup work that cannot be represented as loaded page data or normal update behavior. Rally-generated browser glue calls `init` when it exists; otherwise it constructs the page with `initial_model` and no effect. Rally-generated SSR glue uses `initial_model` so server rendering never depends on browser-only effects.

`Loaded(Result(data, LoadError))` and `Saved(Result(data, SaveError))` are normal browser `Msg` constructors. The server returns page data directly inside `Result`; wrapper types such as `LoadData` or `SaveData` are optional and should only exist when the page needs a named multi-field payload.

`ServerMsg` is page local. `server.send` returns a Lustre `Effect(Msg)`, not a separate Rally type. Rally generates the per-page transport, request-result correlation, codecs, hydration, SSR, browser boot, and server dispatch needed to connect the page to the runtime.
