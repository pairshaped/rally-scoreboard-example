---
# scoreboard-unified-c72y
title: Apply modern Gleam record and label syntax
status: completed
type: task
priority: normal
created_at: 2026-06-06T01:30:13Z
updated_at: 2026-06-06T01:35:54Z
---

Audit handwritten scoreboard modules for places that should use current Gleam record update and label shorthand syntax. Avoid generated files. Run formatter and validation.\n\n- [x] Audit handwritten modules for update and label shorthand opportunities\n- [x] Apply syntax cleanup where it improves clarity\n- [x] Format and validate\n- [x] Record summary and complete bean

## Summary of Changes\n\nAudited handwritten Scoreboard modules for modern Gleam syntax opportunities. Applied label shorthand where the field label and local value already match, including SSR/auth/root handlers, websocket dispatch, load/save adapters, and page data loaders. Kept record creation for the current one-field page models because Gleam reports record updates there as redundant. Excluded generated files from the final diff.\n\nValidation run:\n- gleam format src/admin/pages/games.gleam src/admin_app.gleam src/app_auth_http.gleam src/app_document.gleam src/app_ssr.gleam src/app_ws.gleam src/broadcasts.gleam src/public/pages/games.gleam src/public/pages/games/id_.gleam src/public/pages/standings.gleam src/public/pages/teams/slug_.gleam src/public_app.gleam src/scoreboard_unified.gleam\n- TEMP=./tmp gleam test --target erlang\n- gleam build --target javascript\n- git diff --check
