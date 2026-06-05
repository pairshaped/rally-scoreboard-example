---
# scoreboard-unified-css1
title: Investigate moving inline CSS to a static asset
status: completed
type: task
priority: normal
tags:
    - rally
    - assets
    - dx
created_at: 2026-06-05T18:00:00Z
updated_at: 2026-06-05T18:51:58Z
parent: scoreboard-unified-r0ut
---

## What to investigate

`src/app_assets.gleam` currently stores the application stylesheet as a large Gleam string that `app_document.gleam` embeds into the document. That is questionable authoring ergonomics. CSS is not Gleam behavior, and keeping hundreds of lines of CSS inside a root Gleam module makes styling harder to read, edit, format, and eventually hand to normal asset tooling.

The likely destination is a normal static CSS file that the document links or embeds through a small asset helper. The investigation should decide whether this belongs purely in Scoreboard or whether Rally should provide a static-asset helper/convention for app-authored CSS.

## Questions to answer

- Should Scoreboard move this CSS into an authored static file such as `src/assets/app.css`, `priv/static/app.css`, or another established project location?
- Should `app_document.gleam` link the CSS file, inline it after reading it, or ask a Rally runtime helper for the URL/content?
- How should this interact with Rally's existing generated `/_build/*` static asset serving?
- Does Rally need a first-class convention for authored static assets, or is this just app-owned document behavior?
- Can the move preserve current dark-mode variables and visual behavior without changing app shell code?

## Acceptance criteria

- The investigation names the preferred asset location and serving/embedding mechanism.
- The decision keeps CSS authoring in CSS, not in a Gleam string.
- The document renderer remains simple and does not grow another root framework adapter.
- If Rally support is needed, create or update a Rally bean with the generator/runtime work.
- Browser smoke or visual check confirms the page styling still loads.

## Validation

- `gleam build --target erlang`
- `gleam build --target javascript`
- `npm run test:browser`

## Decision

Move the app stylesheet to `priv/static/app.css` and serve it at `/assets/app.css` from Scoreboard using Rally's existing `rally/runtime/static.serve_asset` helper. The document links the stylesheet instead of embedding CSS text. This keeps CSS authored as CSS, keeps `app_document.gleam` simple, and does not require new Rally generator or runtime work.

## Summary of Changes

- Replaced `src/app_assets.gleam` with `priv/static/app.css`.
- Updated `app_document.gleam` to link `/assets/app.css`.
- Updated `scoreboard_unified.gleam` to serve `/assets/*` from `priv/static`.
- Added browser smoke coverage that fetches `/assets/app.css`, checks its CSS content type, and verifies Scoreboard CSS is present.
