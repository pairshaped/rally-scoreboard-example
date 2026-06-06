---
# scoreboard-unified-dknw
title: Inline trivial loaded helpers in scoreboard pages
status: completed
type: task
priority: normal
created_at: 2026-06-06T01:27:54Z
updated_at: 2026-06-06T01:29:44Z
---

Audit scoreboard modules for one-line private helpers like apply_loaded, inline wrappers that do not earn a function boundary, run formatter and relevant validation.\n\n- [x] Audit page and root modules for trivial private wrappers\n- [x] Inline apply_loaded-style wrappers\n- [x] Format and validate\n- [x] Record summary and complete bean

## Summary of Changes\n\nInlined the trivial apply_loaded helpers in the public games, public game detail, public standings, public team detail, and admin games pages. Kept public page contract functions and target-specific stubs because Rally/Proute calls them by convention and they are boundary hooks, not private convenience wrappers.\n\nValidation run:\n- gleam format src/public/pages/games.gleam src/public/pages/standings.gleam src/public/pages/games/id_.gleam src/public/pages/teams/slug_.gleam src/admin/pages/games.gleam\n- TEMP=./tmp gleam test --target erlang\n- gleam build --target javascript\n- git diff --check
