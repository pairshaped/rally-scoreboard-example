# Use Page Local Rally Contracts

Rally Scoreboard is the chase target for the next Rally page model: one root Gleam package, no generated client app, and page modules that look like ordinary TEA SPA pages with Rally hooks added around the TEA core. Page modules own their local `Model`, browser `Msg`, page-local `ServerMsg`, `initial_model`, optional `init`, `view`, `update`, optional broadcast hooks, and Erlang-only server hooks.

Page modules are also the author-facing routing surface. The page filename and path decide the route. Authored page code should not match generated route constructors, parse route params from strings, or wrap itself in generated page enums. Route params arrive through the generated page input shape, and generated Proute/Rally glue owns route dispatch around the page.

The source model is one authored `src/` tree with target annotations, not separate generated client and server packages.

The default page shape is:

```gleam
import broadcasts
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

/// Required because generated/proute/public/pages module calls this to construct
/// an empty page before Rally applies hydrated or freshly loaded data.
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

// UPDATE

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

// BROADCAST

/// Required because generated/rally/browser_app module calls this to sync active
/// broadcast topics.
pub fn broadcast_subscriptions(model: Model) -> List(broadcasts.Topic) {
  []
}

/// Required because generated/rally/browser_app module calls this after a
/// broadcast frame is decoded for one of this page's active topics.
pub fn apply_broadcast(model: Model, event: broadcasts.Event) -> #(Model, Effect(Msg)) {
  todo
}

// SERVER

@target(erlang)
/// Required because generated/rally/server_ssr and generated/rally/server_ws
/// modules call this, then wrap page data in the Rally/Libero load result shape.
pub fn load(ctx, params) -> Result(List(Game), runtime_load.LoadError) {
  todo
}

@target(erlang)
/// Required because generated/rally/server_ws module calls this after decoding
/// a page-local server command.
pub fn handle(ctx, msg: ServerMsg) -> Result(Game, SaveError) {
  todo
}
```

Shared declarations appear before `// SERVER`. Erlang declarations appear under `// SERVER`. Imports follow the house style from ADR 0007: shared imports first, then Erlang-targeted imports, then JavaScript-targeted imports. The section comments are a human convention; Rally should validate function names, signatures, target availability, and wire-visible types, not rely on comments.

The page function contract is:

| Function | Status | Generated caller |
| --- | --- | --- |
| `initial_model` | Required for every page. | `generated/proute/<mount>/pages` constructs empty page models for browser routing and SSR. |
| `init` | Optional. | `generated/proute/<mount>/pages` calls it when the route first builds a page that defines it. |
| `update` | Required TEA page function. | `generated/proute/<mount>/pages` forwards active page messages. |
| `view` | Required TEA page function. | `generated/proute/<mount>/pages` renders the active page. |
| `broadcast_subscriptions` | Required for broadcast-aware pages. | `generated/rally/browser_app` syncs active broadcast topics from the current route/model. |
| `apply_broadcast` | Required for broadcast-aware pages. | `generated/rally/browser_app` applies decoded broadcast events to the active page. |
| `load` | Required for pages that use standard Rally page data loading. | `generated/rally/server_ssr` and `generated/rally/server_ws` call it and wrap the result in the Rally/Libero load shape. |
| `handle` | Required for pages that send page-local server commands. | `generated/rally/server_ws` calls it after decoding a page-local command. |

`init` should exist only when a page needs page-local browser startup work that cannot be represented as loaded page data or normal update behavior. Standard page data loading belongs to Rally-generated glue.

`Loaded(Result(data, runtime_load.LoadError))` and `Saved(Result(data, SaveError))` are normal browser `Msg` constructors. The standard load error type comes from Rally runtime. Save errors stay page-local unless Rally grows a standard save boundary. The server returns page data directly inside `Result`; wrapper types such as `LoadData` or `SaveData` are optional and should only exist when the page needs a named multi-field payload.

Pages that care about broadcasts expose `broadcast_subscriptions(...)` and `apply_broadcast(...)` in a `// BROADCAST` section. These hooks are a required pair for broadcast-aware pages because `generated/rally/browser_app` calls them after route, page, update, and broadcast state changes. `broadcast_subscriptions` returns typed app topic values, usually from `broadcasts.gleam`; `apply_broadcast` applies decoded broadcast events to the page model after generated Rally glue has handled transport decoding, server-side filtering, and page dispatch.

`ServerMsg` is page local. `server.send` returns a Lustre `Effect(Msg)`, not a separate Rally type. Rally generates the per-page transport, request-result correlation, codecs, hydration, SSR, browser boot, and server dispatch needed to connect the page to the runtime.
