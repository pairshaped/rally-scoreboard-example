# Rally Single-Source Projection

This is an exploratory design note for a possible Rally direction: author one Gleam application source tree, then generate the client and server packages from it.

The goal is a TEA-feeling app with explicit cross-target behavior and simple ETF. Code can be used by both targets when it is actually safe for both.

## Working Thesis

Rally should project one authored app into two generated Gleam programs:

```text
src/
  authored app

.generated/client/src/
  browser-safe projection

.generated/server/src/
  server-safe projection
```

There does not need to be a user-facing `shared` target. Code that is reachable from both projections is emitted into both outputs. Code reachable only from one projection is emitted only there.

The target rule is capability-based:

- client output must not contain server-only capabilities such as database access, secrets, filesystem persistence, or server runtime APIs
- server output must not contain browser-only capabilities such as DOM access, browser storage, drag/drop, or JavaScript browser callbacks
- neutral code can appear in both outputs

This is a better mental model than asking the author to classify every module as client, server, or shared.

## Authoring Shape

The less fancy version looks more viable than automatic branch slicing.

Pages or mount modules use convention-named target roots:

```gleam
pub type ClientMsg {
  NavigateToGame(Int)
  AdjustHome(Int, Int, Int, Int)
  FromServer(ToClient)
}

pub type ServerMsg {
  FromClient(ToServer)
  SessionConnected
  SessionDisconnected
}

pub fn client_init(...) { ... }
pub fn server_init(...) { ... }

pub fn client_update(model, msg) { ... }
pub fn server_update(model, msg) { ... }

pub fn client_subscriptions(model) { ... }
pub fn server_subscriptions(model) { ... }
```

Generated outputs normalize the conventional names:

```text
client_update        -> update
client_subscriptions -> subscriptions
ClientMsg            -> Msg

server_update        -> update
server_subscriptions -> subscriptions
ServerMsg            -> Msg
```

This keeps the TEA shape while avoiding the hardest version of source slicing. Rally does not have to infer which branches of one combined `update` belong to which target. The author names the target roots and Rally proves the graph is clean.

## Wire Contract

Keep root `ToServer` and `ToClient`.

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

The root protocol stays app-level and globally unique. That keeps ETF generation boring:

- one `ToServer` graph
- one `ToClient` graph
- one domain wire graph
- one global constructor uniqueness rule

Page-local `Model` and `ClientMsg` are still useful. Page-local wire/domain types are the part that made ETF preprocessing and namespace handling expensive.

## Projection Rules

For each output, Rally starts from known target roots.

Client roots:

- `client_init`
- `client_update`
- `client_subscriptions`
- `ClientMsg`
- interactive `view`
- generated `ToClient -> ClientMsg` adapter
- generated `ClientMsg -> ToServer` send path
- root `ToServer` and `ToClient` codec graph

Server roots:

- `server_init`
- `server_update`
- `server_subscriptions`
- server route handlers
- generated `ToServer -> ServerMsg` adapter
- generated `ServerMsg -> ToClient` send path
- SSR render entrypoints
- root `ToServer` and `ToClient` codec graph

Then:

1. Include declarations reachable from the target roots.
2. Drop declarations that are unreachable from that target.
3. Emit imports needed by the retained declarations.
4. Fail if any retained declaration reaches a forbidden capability for that target.
5. Print the shortest useful call path when a forbidden capability leaks.

Naming conventions identify roots. Reachability decides the rest.

## Taint Tracing

Taint still matters, but split target roots make it validation instead of inference.

Example server taint:

```text
server_update
  -> update_score
    -> games_sql.update_game_score
      -> sqlight.query
```

Example client taint:

```text
client_update
  -> drag_update
    -> browser_dom.measure
```

Those are fine when they stay under the matching target root.

The failure case is a wrong-target path:

```text
client_update
  -> save_score
    -> games_sql.update_game_score
```

That should fail before code generation with a diagnostic like:

```text
client_update cannot reach server-only capability `games_sql.update_game_score`.

Call path:
  client_update
  save_score
  games_sql.update_game_score

Move the database write behind a ToServer command handled by server_update.
```

## View Shape

`view` is the awkward part because it returns messages through event handlers.

The current sibling app already has the pattern we want:

```gleam
pub fn view(
  games: List(PublicGameSummary),
  on_navigate_team: fn(String) -> msg,
  on_navigate_game: fn(Int) -> msg,
) -> Element(msg)
```

The root client passes callbacks that produce browser messages. SSR can render the same structure because the view is parameterized over `msg`.

For the single-source design, the default should be:

```gleam
pub fn view(model: Model) -> Element(ClientMsg)
```

That means interactive DOM events are client messages. Server behavior must go through `ToServer` and then `ServerMsg`; a browser event should never emit `ServerMsg` directly.

If the server projection needs to render the same view, it can include `ClientMsg` as an inert type for static rendering. The server renderer does not need to execute browser events. This is already close to what the sibling shared views imply: event payloads can be present in the tree type without becoming server behavior.

The safer fallback, if direct `Element(ClientMsg)` becomes painful, is the existing callback style:

```gleam
pub fn view(
  model: Model,
  events: ViewEvents(msg),
) -> Element(msg)
```

That keeps one visual view while letting generated client and server entrypoints choose different event adapters.

## What The Current Scoreboard Code Shows

The current sibling app already has most of the pieces, but spread across `client`, `server`, and `shared`.

Current root protocol:

- `shared/src/shared/api/to_server.gleam`
- `shared/src/shared/api/to_client.gleam`
- `shared/src/shared/api/domain/**/*.gleam`

This part should survive mostly unchanged. It is the good part.

Current client roots:

- `client/src/scoreboard_public_client.gleam`
- `client/src/scoreboard_admin_client.gleam`
- `client/src/client/**/pages/**/*.gleam`

These modules own browser `Msg`, hydration, navigation, local page updates, and `ToClient` handlers.

Current server roots:

- `server/src/server/public/backend.gleam`
- `server/src/server/admin/backend.gleam`
- `server/src/server/**/pages/**/*.gleam`

These modules own `backend.Msg`, `backend.update`, route request context, DB-backed handlers, and `ToServer` dispatch.

Current target-neutral views and boot requests:

- `shared/src/shared/**/pages/**/*.gleam`
- `shared/src/shared/components/**/*.gleam`

These modules are the best evidence that a single-source projection is plausible. They already contain Lustre views with events, and they compile in the shared package by keeping messages generic.

Current duplication that the projection could remove:

- repeated route/init/load logic in the root clients
- page boot declarations in `shared` with page state handlers in `client` and loaders in `server`
- manual connection between shared view callbacks and nested generated page messages
- package layout ceremony for code that wants to be authored as one page

Current behavior to preserve:

- root `ToServer` and `ToClient`
- constructor-named server handlers
- constructor-named client `ToClient` handlers
- true hydration with embedded boot `ToClient` data
- compact ETF payloads
- no page-local wire/domain types

## Gleam Compiler And Tooling Findings

Gleam has three relevant tooling surfaces.

### Package Interface JSON

The installed compiler exposes:

```sh
gleam export package-interface --out <OUTPUT>
```

The output is JSON for the public package API. It includes:

- package name and version
- public modules
- module docs
- public type aliases
- public custom types and constructors
- public constants
- public functions
- parameter labels and types
- return types
- implementation target facts for public functions and constants

In this app, running it in `shared/` exposes `shared/api/to_server`, `shared/api/to_client`, and the domain types in a directly useful shape for codec generation.

This should probably be the first input for protocol and public API work. It is much safer than poking compiler internals when Rally only needs public type shapes.

Its limits matter:

- it only exports public API
- it does not expose private helper declarations
- it does not expose call sites or a call graph
- it does not say which public function calls which private function
- it is not enough to project one source tree into client/server outputs

So package-interface JSON can simplify ETF/codegen discovery, but it cannot prove target reachability by itself.

### LSP

The Gleam language server already does project compilation, definition lookup, type definition lookup, references, hovers, document symbols, renames, and code actions.

Useful source facts from `gleam-lang/gleam`:

- [`language-server/src/compiler.rs`](https://github.com/gleam-lang/gleam/blob/main/language-server/src/compiler.rs) wraps `ProjectCompiler` and keeps compiled modules, source paths, line numbers, and module interfaces.
- [`language-server/src/engine.rs`](https://github.com/gleam-lang/gleam/blob/main/language-server/src/engine.rs) exposes definition, type definition, references, hover, document symbols, and rename behavior.
- The LSP uses `ModuleInterface`, `TypedModule`, source spans, and typed located nodes internally.

The LSP is useful evidence that Gleam already has the semantic information Rally would need. It may also be useful as a spike path for editor-style queries.

I would not make LSP RPC the main Rally generator backend unless a spike proves it is pleasant. Rally needs batch analysis, projection, import rewriting, and generated source emission. Driving that through request/response editor APIs is likely to be awkward.

### Compiler Internals

Useful source facts from `gleam-lang/gleam`:

- [`compiler-core/src/parse.rs`](https://github.com/gleam-lang/gleam/blob/main/compiler-core/src/parse.rs) exposes `parse_module`.
- [`compiler-core/src/ast.rs`](https://github.com/gleam-lang/gleam/blob/main/compiler-core/src/ast.rs) has `UntypedModule`, `TargetedDefinition`, `Definition`, `Function`, and `Import`.
- `TargetedDefinition` already models `@target(erlang)` and `@target(javascript)`.
- `UntypedModule.dependencies(target)` already walks imports visible for a target.
- `Function` records `external_erlang` and `external_javascript`.
- `Import` records the module, alias, unqualified values, unqualified types, and source spans.
- [`compiler-core/src/ast/typed.rs`](https://github.com/gleam-lang/gleam/blob/main/compiler-core/src/ast/typed.rs) has `TypedExpr::Call`, `TypedExpr::Var`, and `TypedExpr::ModuleSelect`.
- [`compiler-core/src/package_interface.rs`](https://github.com/gleam-lang/gleam/blob/main/compiler-core/src/package_interface.rs) defines the JSON package interface shape and target implementation fields.
- typed value constructors include module/function identity and external target metadata.

That means a Rust projector can plausibly do the work with compiler-quality inputs during a research spike:

- parse modules
- collect imports
- find conventional roots
- inspect typed calls
- detect externals and target attributes
- produce source-span diagnostics

This may still be the right foundation for internal use. The design rule is to do whatever is simplest while keeping the maintenance cost visible. `gleam-core` internals are more likely to change between Gleam releases, so Rally should expect occasional updates when the pinned Gleam version moves.

The useful architecture boundary is:

1. Use package-interface JSON for public wire/API discovery.
2. Use whichever analyzer is simplest for private reachability, call tracing, and source spans.
3. Keep compiler-internal usage behind one Rally-owned analyzer boundary when that is cheap.
4. Use ordinary `gleam check`, `gleam format`, and target-specific compilation as the compatibility oracle.

For internal use, directly using `gleam-core` may be the fastest honest path. A Rally-owned parser is only worth building if compiler internals become more expensive than the maintenance they save.

## Validation Against This App

This app suggests the idea is viable, with two important constraints.

First, split target roots are enough for most of the current shape. Admin score buttons would live under `client_update`; DB writes would live under `server_update` or server handlers; `ToServer.UpdateScore` remains the bridge.

Second, `view` should stay client-message-shaped. The server can reuse it for SSR only as static markup. Server work should not be directly represented as DOM event messages.

A plausible single-source admin games page would combine today’s three modules:

```text
client/src/client/admin/pages/games.gleam
server/src/server/admin/pages/games.gleam
shared/src/shared/admin/pages/games.gleam
```

into one authored page that contains:

- page `Model`
- `ClientMsg`
- `client_update`
- constructor-named `ToClient` handlers
- `server_update` or constructor-named server handlers
- `init_requests`
- `view`
- helper functions

Rally would project:

- client state/update/view/ToClient handlers into the client output
- server handlers/DB helpers into the server output
- neutral domain/view helpers into whichever side reaches them

## Recommended First Spike

Do not start with arbitrary function-level slicing.

Start with declaration-level projection and convention roots:

1. Generate package-interface JSON for the root app and confirm it is enough for `ToServer`, `ToClient`, and domain codec discovery.
2. Prototype the simplest analyzer path, including direct `gleam-core` usage if that is faster than building a parser.
3. Find `ClientMsg`, `ServerMsg`, `client_update`, and `server_update`.
4. Build a call graph from typed calls for a tiny subset of Gleam expressions.
5. Mark known capability modules as client-only or server-only.
6. Project reachable declarations into client and server files.
7. Rebuild imports from retained declaration usage.
8. Run `gleam format` and `gleam check` on both generated outputs.

Do this against a small page first, then the admin games page. Admin games is the useful test because it has real client events, real server writes, shared view code, and protocol messages.

## Open Questions

- Can package-interface JSON fully replace Libero's current type walking for public wire contracts?
- Is LSP useful as an optional editor integration later, separate from generation?
- Is direct `gleam-core` usage simpler than a Rally-owned parser for the first internal version?
- How much maintenance should Rally expect when the pinned Gleam version changes?
- Does the typed AST preserve enough source structure to emit human-readable projected Gleam, or should Rally use typed AST only for analysis and untyped source spans for emission?
- Should `view` be authored as `Element(ClientMsg)` or as generic callback-injected `Element(msg)`?
- Are `@target(erlang)` and `@target(javascript)` useful as escape hatches, or should Rally avoid them in authored app code and use capability modules instead?
- Where should capability declarations live: built-in module prefixes, Rally config, or annotations?
- How much should generated outputs preserve source comments?

## Current Read

This is a better direction than page-local ETF namespaces.

The real design is not “infer everything.” It is:

> Write one TEA-shaped Gleam app. Name the client and server roots. Keep `ToServer` and `ToClient` as the deliberate wire contract. Rally projects the two target programs and rejects forbidden capability leaks.

That is still compiler-shaped work, but it is bounded. It avoids the worst version of branch slicing, keeps ETF simple, and attacks the sibling app’s biggest ergonomic weakness without giving up its performance and hydration wins.
