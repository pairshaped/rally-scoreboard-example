---
# scoreboard-unified-v4f9
title: Replace root API contracts with a page-local public games load
status: done
type: feature
priority: high
tags:
    - rally
    - chase
created_at: 2026-06-04T03:38:31Z
updated_at: 2026-06-04T03:56:18Z
parent: scoreboard-unified-wm8p
---

## What to build

Replace the temporary global load contract for the public games page with a page-local server handler and page-local wire payload. The public games page should load through its own page contract, not through root `ToServer.LoadGames`, root `ToClient.GamesLoaded`, or shared root game summary/domain types.

This is the first tracer bullet for the intended Rally direction: centralized `src/` authoring, page-owned domain models, client behavior in Gleam, and only thin generated wire glue.

## Plan outline

- Pick the public games page as the first page-local load slice.
- Keep the page's domain model owned by the page module.
- Generate or hand-prototype the wire request, response codec, and route dispatch for that page only.
- Have navigation load data through the correlated `send_load(..., on_result: ...)` path.
- Remove the root API type references for this page's load path.
- Keep broadcasts for score updates working while the root broadcast bridge still exists.

## Acceptance criteria

- [x] Public games navigation loads via a page-local load contract.
- [x] The public games load path does not reference root `api/to_server`, root `api/to_client`, or root `api/domain/game` types.
- [x] Load success arrives as one correlated result frame carrying the loaded payload.
- [x] Existing public games SSR, hydration, navigation, and live score update tests pass.
- [x] The implementation documents any temporary bridge code that should later be generated.

## Blocked by

None - can start immediately.

## Progress

Implemented the browser-navigation tracer for Home/Games using a page-local public games wire module and correlated load result. The websocket server now handles `public/pages/games` by calling `public/pages/games.load` directly and returning a page-local `PublicGamesLoaded` payload.

This is still not the full bean. SSR hydration for public games still uses the temporary root API bridge, and the hand-written generated glue needs to become Rally output.

Validated with:

- `gleam build --target javascript`
- `gleam build --target erlang`
- `gleam test`
- `node test/ws_result_smoke.mjs`
- `node test/browser_smoke.mjs`

Completed the tracer by moving direct SSR/hydration for Home/Games onto the page-local public games contract. Server rendering now calls `public/pages/games.load` directly, renders the page-local model, and emits a page-local hydration result frame. Browser boot decodes that page-local hydration before falling back to root hydration for other routes.

Removed the stale Home/Games `LoadGames` request fallback from generated public boot glue. The hand-written generated-code behavior remains intentional chase debt and is tracked by `scoreboard-unified-adc2`.

Validated with:

- `gleam build --target javascript`
- `gleam build --target erlang`
- `gleam test`
- `node test/ws_result_smoke.mjs`
- `SCOREBOARD_BASE_URL=http://localhost:8097 node test/browser_smoke.mjs`
