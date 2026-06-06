---
# scoreboard-unified-2j70
title: Adopt handle_save save hook
status: completed
type: task
priority: normal
created_at: 2026-06-06T19:09:43Z
updated_at: 2026-06-06T19:18:56Z
---

Update the Rally Scoreboard Example to use the new page-owned handle_save hook name and regenerate Rally artifacts.

## Summary of Changes

- Renamed the admin games page save hook from `handle` to `handle_save`.
- Updated tests and docs that referenced the old hook name.
- Regenerated Rally and Libero artifacts against the updated local Rally/Libero path.

## Validation

- gleam format
- git diff --check
- gleam run -m rally build
- gleam test: 24 passed
