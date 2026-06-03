# Unified Target Source

Scoreboard Unified uses one authored Gleam source tree. The source tree compiles directly for JavaScript and Erlang, with target-specific declarations and imports marked where target-specific behavior starts.

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
import lustre/effect.{type Effect}
import lustre/element.{type Element}

@target(javascript)
import generated/rally/page_client

@target(erlang)
import generated/sql/games_sql

pub type Model {
  Model(games: List(Game), saving: Bool)
}

pub type Msg {
  AdjustHome(id: Int, delta: Int)
  Loaded(Result(List(Game), LoadError))
  Saved(Result(Game, SaveError))
}

pub type ServerCommand {
  AdjustHome(id: Int, delta: Int)
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
  todo
}

// SERVER

@target(erlang)
pub fn load(ctx, params) -> Result(List(Game), LoadError) {
  todo
}

@target(erlang)
pub fn handle(ctx, command: ServerCommand) -> Result(Game, SaveError) {
  todo
}
```

Shared imports come first, followed by JavaScript-targeted imports, then Erlang-targeted imports. The module body follows the same order: shared types and view first, then `// CLIENT`, then `// SERVER`.

The section comments are for humans. Rally validates the page contract by function names, signatures, target availability, and wire-visible types.

## Page Data

Page data shapes belong to the page that renders and updates them. A list page, detail page, and form page should duplicate similar fields instead of sharing one model just because their current shapes overlap.

Shared types are reserved for stable app concepts independent of a page, such as identifiers, enums, or value objects. Page payloads, form models, table rows, detail data, and save responses stay page local.

## Generated Source

Generated source lives under `src/generated`:

```text
src/generated/proute/**/*.gleam
src/generated/rally/**/*.gleam
src/generated/sql/**/*.gleam
```

Proute owns file routes, page enums, route params, query params, and page dispatch shape. Rally consumes Proute output and generates page protocol code, browser boot, hydration, SSR, client transport, and server dispatch. Marmot writes typed SQL modules for Erlang-only server paths.

Generated modules use the same target annotation rules as user-authored modules.

## Target Boundaries

Target annotations belong where target-specific behavior begins:

- JavaScript-only imports and declarations for browser APIs, DOM effects, browser storage, and browser transport setup
- Erlang-only imports and declarations for SQL, secrets, filesystem access, server runtime APIs, and server handlers
- unannotated declarations only when they compile and make sense on both targets

Target-specific imports should be annotated too. Inactive-target builds should not retain useless or invalid imports.

## SQL And Marmot

Marmot output belongs under root `src/generated/sql`.

The authored root contains SQL files:

```text
src/sql/**/*.sql
```

Server code imports these modules from Erlang-only declarations. JavaScript builds must not keep code paths that import SQL modules.
