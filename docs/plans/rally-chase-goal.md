# Rally Chase Goal Plan

Scoreboard Unified should become the app shape Rally chases: one authored `src/` tree, Proute-owned routing, target annotations for client/server code, page-local contracts, page-local domain data, and generated Rally glue under `src/generated/rally`.

The target is not to make the current app prettier in place. The target is to make the desired Rally app obvious from the code.

## Principles

1. Pages read like TEA SPA pages first.
2. Shared page code appears before `// CLIENT`.
3. JavaScript-only lifecycle and update code appears under `// CLIENT`.
4. Erlang-only load and server request handlers appear under `// SERVER`.
5. Page data shapes stay page-local.
6. Pages do not import domain models from other pages.
7. Wire-crossing types can reference only page-local types, `src/wire/**` types, primitives, and standard containers.
8. Proute owns route discovery, route params, query params, page enums, and page dispatch shape.
9. Proute identifies the page, action, or channel before Rally decodes page-local wire payloads.
10. Rally-generated framework glue lives under `src/generated/rally`.
11. Rally does not generate a full client app from server-shaped source.
12. Generated code is limited to thin wire glue, codecs, route glue, build metadata, browser boot, hydration, SSR, client transport, and server dispatch.
13. Client-side application behavior is authored in Gleam. JS or TS is only for tiny FFI modules that touch browser APIs.
14. Whole modules full of target annotations are generated or split out of user-authored code.
15. Authored SQL lives beside the page or workflow that owns it, in a local `sql/` directory.
16. Generated SQL lives under `src/generated/sql`.
17. Authored and generated modules preserve stable Rally/Gleam house style.
18. Both target builds are required checks.

## Non-Goals

- Do not implement Rally generator changes in this repo.
- Do not preserve the global app API shape.
- Do not introduce shared page payload types to reduce duplicate fields.
- Do not make Proute responsible for Rally transport, SSR, hydration, or codecs.
- Do not hand-write polished generator output before the page contract is proven.
- Do not write client application behavior in JS or TS.
- Do not allow helper, service, query, business, or display types to cross the wire, even transitively.

## Boundary Rules

### Target Annotations

The chase must test one central authored `src/` tree that uses `@target(erlang)` and `@target(javascript)` where platform behavior begins. It must not test the old generated-client-package model.

### Wire Type Ownership

Wire-visible page protocols may reference:

- types defined in the owning page module
- types defined under `src/wire/**`
- primitives
- standard containers such as `List`, `Result`, `Option`, tuples, and records that contain approved wire-visible types

Wire-visible page protocols must not reference helper, service, query, business, formatting, or display types. This rule is transitive: if an approved-looking type contains an unapproved owned type, the protocol fails.

Non-wire helpers are allowed. A page may call helper, service, query, business, or formatting modules as behavior. Their owned shapes just cannot become wire contract shapes.

### Route First, Decode Second

Proute should identify the destination page, action, or channel before Rally decodes page-local payloads. This lets two pages both define `Item` without requiring global type identity hashes.

### Boundary Diagnostics

Boundary failures should name:

- the violated contract
- the page, action, or channel being checked
- the offending type or import
- the path that made it reachable
- the smallest likely fix

### Client Escape Hatch

Client behavior is authored in Gleam. JS or TS is allowed only as a tiny FFI shim for browser APIs that Gleam cannot call directly.

## Authoring Style

Use the existing Rally/Gleam house style for module layout. Section comment headers should separate major module regions when the module is large enough to benefit from them.

Examples:

```text
// TYPES
// INIT
// UPDATE
// VIEW
// EFFECTS
// HELPERS
```

Small modules do not need headers. Large modules should use headers consistently rather than relying on incidental ordering.

## Import Grouping

Imports are grouped in this order:

1. generated modules
2. standard library modules
3. external package modules
4. app/root shared modules
5. page-local or sibling modules

Within each group, imports are sorted alphabetically.

Generated output and rewritten source should preserve this import order and module layout style where `gleam format` allows it. The formatter owns final import ordering and may re-sort imports or collapse groups. Rally should not fight the formatter, emit random import order, or churn section layout when the semantics did not change.

## Stop Conditions

Stop the chase and revisit the design if any of these are true:

- target annotations cannot escape generated-client-package assumptions
- page-local decoding still requires global type identity hashes
- boundary checking needs brittle whole-program magic
- JS or TS grows beyond tiny browser API FFI shims
- generated client code starts to look like an app instead of wire glue
- Rally cannot produce useful diagnostics for bad type or import boundaries
- authored SQL colocation makes Marmot output unstable or hard to import

## Slice 1: Public Games Page Contract

Convert `src/public/pages/games.gleam` to the target page shape.

Expected changes:

- Move the page's list data shape into the page module.
- Replace app-level load messages with a page-local `load`.
- Add a page-local `ServerMsg` only if the page needs server requests beyond load.
- Keep `view` target-neutral.
- Keep JavaScript `init` and `update` under `// CLIENT`.
- Keep Erlang DB loading under `// SERVER`.
- Keep imports grouped as shared, JavaScript, Erlang.

Acceptance:

```sh
gleam build --target javascript
gleam build --target erlang
```

The public games page should no longer depend on app-wide API domain models for its page payload.

## Slice 2: Admin Games Page Contract

Convert `src/admin/pages/games.gleam` to the target page shape.

Expected changes:

- Move admin list data and save response data into the page module.
- Replace app-level update dispatch with page-local `ServerMsg`.
- Keep score adjustment and finalization as browser `Msg` constructors.
- Return save result data directly inside `Result`.
- Send page-local server messages with a Rally API/RPC effect whose `on_result` callback receives `Result(success, error)` and dispatches the selected local browser `Msg`.
- Treat current `send_load` and `send_save` helpers as temporary bridge code. The target Rally API is `server.send(ServerMsg, on_result: ...)` once page-local result generation owns the result type.
- Keep server DB writes under `// SERVER`.

Acceptance:

```sh
gleam build --target javascript
gleam build --target erlang
```

`app_api.gleam` should no longer own admin games domain decisions.

## Slice 3: Public Detail Pages

Convert the detail-style pages:

- `src/public/pages/games/id_.gleam`
- `src/public/pages/teams/slug_.gleam`
- `src/public/pages/standings.gleam`

Expected changes:

- Keep each page's detail/list payload local to that page.
- Duplicate similar fields rather than sharing page payloads.
- Use shared types only for stable app concepts that are meaningful outside a page.
- Keep server load functions near the page.

Acceptance:

```sh
gleam build --target javascript
gleam build --target erlang
```

No page imports a domain model from another page.

## Slice 4: Remove App-Level API Dispatch

Shrink or remove `src/app_api.gleam`.

Expected changes:

- Remove global server-message and app-data dispatch as user-authored behavior.
- Move page behavior into page modules.
- Leave only generated-shaped routing from decoded page protocol to page handlers.
- Move that generated-shaped code under `src/generated/rally` once the shape is clear.

Acceptance:

```sh
gleam build --target javascript
gleam build --target erlang
rg "api/to_server|api/to_client|ToServer|ToClient" src docs README.md
```

The `rg` command should find no live design or source dependency on global API message roots.

## Slice 5: Prove Wire Boundary Validation

Make the chase prove Rally can reject the wrong wire shapes.

Expected changes:

- Use `src/wire/**` as the only approved root wire namespace.
- Keep page-local payloads local to their page modules.
- Add fixture or example failures for helper, service, query, business, and display types crossing the wire.
- Add fixture or example failures for target-specific imports leaking into the wrong target.
- Add fixture or example failures for transitive type leaks.
- Show diagnostics that name the contract, page/action/channel, offending type or import, and reachability path.

Acceptance:

```sh
gleam build --target javascript
gleam build --target erlang
rg "src/wire" README.md docs src
```

The `rg` command should show `src/wire/**` as the approved root wire namespace.

## Slice 6: Prove Route-First Decoding

Make the chase prove two pages can use same-named page-local types without global identity.

Expected changes:

- Add two page protocols that both define a same-named type such as `Item`.
- Route an incoming message to the page, action, or channel before decoding the page-local payload.
- Keep page-local codecs scoped by routed destination.

Acceptance:

```sh
gleam build --target javascript
gleam build --target erlang
```

Two pages should be able to use the same local type names without global type hash collisions.

## Slice 7: Colocate Authored SQL

Move authored SQL files next to the page or workflow that owns the server behavior.

Expected changes:

- Put page-owned SQL under the page module's local `sql/` directory.
- Put workflow-owned SQL under the workflow module's local `sql/` directory.
- Keep generated SQL modules under `src/generated/sql`.
- Keep Erlang-only page handlers importing generated SQL modules.
- Remove the centralized authored `src/sql` tree once all queries have owners.

Acceptance:

```sh
gleam run -m marmot
gleam build --target javascript
gleam build --target erlang
find src -path '*/sql/*.sql' -print
test ! -d src/sql
```

Authored SQL should be colocated with its owner, while generated SQL remains centralized.

## Slice 8: Prove Style Stability

Make the chase prove Rally preserves source style while generating or rewriting code.

Expected changes:

- Use section headers for large authored modules.
- Keep small modules header-free when headers add noise.
- Group imports by generated, standard library, external package, app/root shared, and page-local or sibling modules.
- Sort imports alphabetically within each group.
- Ensure generated output follows the same import grouping.
- Ensure rewritten source does not churn section layout or imports when semantics do not change.

Acceptance:

```sh
gleam build --target javascript
gleam build --target erlang
```

Generated output and transformed source should be stable enough to review without cosmetic churn.

## Slice 9: Extract Generated Rally Glue

Move generated-shaped framework code to `src/generated/rally`.

Expected changes:

- Put generated Rally framework code under `src/generated/rally`.
- Put browser boot, hydration, client transport, page client helpers, SSR glue, and server dispatch glue there.
- Keep user-authored app modules thin.
- Avoid user-authored modules where every import and declaration is target annotated.

Acceptance:

```sh
gleam build --target javascript
gleam build --target erlang
find src/generated/rally -maxdepth 1 -type f
```

Generated Rally glue should live in `src/generated/rally`.

## Slice 10: Proute Boundary

Make Proute the only routing/page-dispatch source of truth.

Expected changes:

- Keep Proute output under `src/generated/proute`.
- Use Proute page enums, route params, query params, and dispatch helpers from Rally glue.
- Do not duplicate route parsing or page enum logic in Rally-shaped code.

Acceptance:

```sh
gleam run -m proute
gleam build --target javascript
gleam build --target erlang
```

Generated Rally glue should consume Proute output instead of re-describing routes.

## Slice 11: Documentation Cleanup

Keep docs aligned with the desired design only.

Expected changes:

- README describes page-local contracts.
- `docs/unified-target-source.md` describes the current target shape.
- ADRs describe intended design, not project history.
- No docs refer to global app API roots.

Acceptance:

```sh
rg "api/to_server|api/to_client|ToServer|ToClient|superseded|legacy" README.md docs
```

The command should find no matches.

## Final Acceptance

Run:

```sh
gleam run -m marmot
gleam run -m proute
gleam run -m libero
gleam build --target javascript
gleam build --target erlang
gleam test
```

The app should compile for both targets, tests should pass, and the source should make the Rally chase target obvious without reading generated code first.
