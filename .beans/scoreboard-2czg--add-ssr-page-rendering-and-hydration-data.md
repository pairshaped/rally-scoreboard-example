---
# scoreboard-2czg
title: Add SSR page rendering and hydration data
status: completed
type: task
priority: normal
tags:
    - ssr
    - hydration
    - erlang-target
    - javascript-target
created_at: 2026-06-01T23:04:09Z
updated_at: 2026-06-01T23:56:02Z
---

## Problem

SSR hydration is not wired up yet.

The server currently sends an empty app root:

- `src/scoreboard_unified.gleam` renders `<div id="app"></div>` for every non-static route.
- `src/public_app.gleam` and `src/admin_app.gleam` always parse the browser path and run generated `pages.load(...)` during client startup.
- Generated `pages.load_sync(...)` exists, but the server does not call it.
- Page modules describe `init_requests` as usable for hydration, but the current boot path sends those requests from the browser after mount instead of embedding server-loaded page state.

The result is client-side boot with an empty shell, not SSR hydration. This is okay for the current SPA navigation spike, but the docs and route shape imply a server-rendered first paint that we do not have.

## Direction

Add a real SSR and hydration path for the unified app:

- route HTTP requests through generated route parsing before rendering the document
- build the initial page model on the Erlang target, using generated page glue and route params
- execute data-backed page `init_requests` on the server or otherwise populate the same page state the websocket response would produce
- render page HTML into `#app` on the server
- embed hydration data in the document as ETF data, using the same Libero-generated codec path as websocket frames
- teach the JavaScript app startup to consume hydration data and skip duplicate initial load requests when the page is already populated
- keep public and admin shared state separate
- preserve existing SPA navigation, websocket updates, and back/forward behavior

The document transport will need a browser-safe wrapper around the ETF bytes, probably base64 in a script tag or data attribute. Do not add a parallel JSON hydration format.

Do not encode sensitive session data into browser-readable hydration payloads. Auth facts exposed to the client should be the same facts the client is allowed to render.

## Current code references

- `src/scoreboard_unified.gleam` owns the HTTP document shell and currently renders the empty app root.
- `src/public_app.gleam` owns public JavaScript startup and currently always calls `pages.load(...)`.
- `src/admin_app.gleam` owns admin JavaScript startup and currently always calls `pages.load(...)`.
- `src/generated/proute/public/pages.gleam` has `load_sync(...)` and `load(...)`.
- `src/generated/proute/admin/pages.gleam` has `load_sync(...)` and `load(...)`.
- `src/server/api.gleam` is the server-side dispatcher for `ToServer` requests that can produce `ToClient` page data.
- Libero-generated codecs are the serialization boundary for both websocket frames and embedded hydration data.
- `docs/adr/0006-default-to-root-api-contracts.md` describes `init_requests` and hydration expectations.
- `docs/adr/0007-use-file-routes-route-kinds-and-mount-contexts.md` describes generated route kinds and mount behavior.

## Acceptance criteria

- A direct HTTP request to `/games` returns HTML with server-rendered app content, not an empty app root.
- A direct HTTP request to a data-backed route embeds ETF hydration data for the client to avoid sending duplicate initial load requests.
- Hydration decode uses the same generated Libero codec path as websocket `ToClient` decoding.
- There is no JSON-only hydration payload or hand-maintained duplicate decoder.
- Public and admin hydration state cannot be confused across mounts.
- SPA navigation still runs destination page load effects after the app has hydrated.
- Browser back/forward still keeps URL and rendered page in sync.
- Invalid or missing hydration data falls back to normal client loading rather than breaking the page.
- `gleam format`, JavaScript build, Erlang build, `glinter`, `beans check`, and a Playwright smoke test pass.
