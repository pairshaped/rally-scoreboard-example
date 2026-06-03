# Rally Chase Goal Plan

Scoreboard Unified should become the app shape Rally chases: one source tree, Proute-owned routing, page-local contracts, page-local domain data, and generated Rally glue under `src/generated/rally`.

The target is not to make the current app prettier in place. The target is to make the desired Rally app obvious from the code.

## Principles

1. Pages read like TEA SPA pages first.
2. Shared page code appears before `// CLIENT`.
3. JavaScript-only lifecycle and update code appears under `// CLIENT`.
4. Erlang-only load and server command handlers appear under `// SERVER`.
5. Page data shapes stay page-local.
6. Pages do not import domain models from other pages.
7. Proute owns route discovery, route params, query params, page enums, and page dispatch shape.
8. Rally-generated framework glue lives under `src/generated/rally`.
9. Whole modules full of target annotations are generated or split out of user-authored code.
10. Both target builds are required checks.

## Non-Goals

- Do not implement Rally generator changes in this repo.
- Do not preserve the global app API shape.
- Do not introduce shared page payload types to reduce duplicate fields.
- Do not make Proute responsible for Rally transport, SSR, hydration, or codecs.
- Do not hand-write polished generator output before the page contract is proven.

## Slice 1: Public Games Page Contract

Convert `src/public/pages/games.gleam` to the target page shape.

Expected changes:

- Move the page's list data shape into the page module.
- Replace app-level load messages with a page-local `load`.
- Add a page-local `ServerCommand` only if the page needs server commands beyond load.
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
- Replace app-level update dispatch with page-local `ServerCommand`.
- Keep score adjustment and finalization as browser `Msg` constructors.
- Return save result data directly inside `Result`.
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

- Remove global command and app-data dispatch as user-authored behavior.
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

## Slice 5: Extract Generated Rally Glue

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

## Slice 6: Proute Boundary

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

## Slice 7: Documentation Cleanup

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
gleam build --target javascript
gleam build --target erlang
gleam test
```

The app should compile for both targets, tests should pass, and the source should make the Rally chase target obvious without reading generated code first.
