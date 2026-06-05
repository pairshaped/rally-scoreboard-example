# Use Page Local Rally Contracts

Scoreboard Unified is the chase target for the next Rally page model: one root Gleam package, no generated client app, and page modules that look like ordinary TEA SPA pages with server handlers added at the bottom. Page modules own their local `Model`, browser `Msg`, page-local `ServerMsg`, shared `view`, JavaScript-only `init` and `update`, and Erlang-only `load` and `handle` functions.

The source model is one authored `src/` tree with target annotations, not separate generated client and server packages.

The default page shape is:

```gleam
import components/ui
import lustre/effect.{type Effect}
import lustre/element.{type Element}

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

// CLIENT

@target(javascript)
pub fn init(games: List(Game)) -> #(Model, Effect(Msg)) {
  #(Model(games: games, saving: False), effect.none())
}

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

`Loaded(Result(data, LoadError))` and `Saved(Result(data, SaveError))` are normal browser `Msg` constructors. The server returns page data directly inside `Result`; wrapper types such as `LoadData` or `SaveData` are optional and should only exist when the page needs a named multi-field payload.

`ServerMsg` is page local. `server.send` returns a Lustre `Effect(Msg)`, not a separate Rally type. Rally generates the per-page transport, request-result correlation, codecs, hydration, SSR, browser boot, and server dispatch needed to connect the page to the runtime.
