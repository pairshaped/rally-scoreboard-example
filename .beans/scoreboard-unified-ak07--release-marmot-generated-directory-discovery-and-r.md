---
# scoreboard-unified-ak07
title: Release Marmot generated-directory discovery and remove the path dependency
status: done
type: task
priority: normal
tags:
    - rally
    - chase
    - sql
created_at: 2026-06-04T03:38:31Z
updated_at: 2026-06-05T01:25:00Z
parent: scoreboard-unified-wm8p
---

## What to build

Finish the SQL locality dependency story. Marmot now has a local fix that skips `src/generated` during default SQL discovery; publish or otherwise version that fix, then move `scoreboard-unified` off `marmot = { path = "../marmot" }` when a usable version exists.

Authored SQL should remain colocated beside owning pages/workflows in local `sql/` directories. Generated Marmot output should stay under generated SQL output.

## Plan outline

- Confirm the Marmot scanner fix is committed and available on the intended branch or release.
- Decide whether Scoreboard should depend on a released Marmot version, a git dependency, or keep the path dependency only for local chase work.
- If releasing, update Marmot version metadata and publish/tag according to the project process.
- Update Scoreboard's dependency and manifest.
- Rerun Marmot generation and verify it does not scan `src/generated` or warn about generated SQL subdirectories.

## Acceptance criteria

- [x] Scoreboard no longer relies on an uncommitted local Marmot scanner fix.
- [x] `gleam run -m marmot` does not scan or warn about `src/generated/sql`.
- [x] Authored SQL remains colocated beside owning pages/workflows.
- [x] Generated SQL modules remain under generated SQL output.
- [x] Dependency and manifest changes are committed.

## Blocked by

None - can start immediately.

## Progress

Moved Scoreboard's dev dependency from `marmot = { path = "../marmot" }` to released `marmot >= 1.7.1 and < 2.0.0`. `gleam run -m marmot` with the released dependency writes the five expected generated SQL modules and does not scan or warn about `src/generated/sql`.

`manifest.toml` is ignored by this repo, so the committed dependency change is `gleam.toml`; the local ignored manifest resolves Marmot from Hex at 1.7.1.

Validated with:

• gleam run -m marmot
• gleam build --target erlang
• gleam build --target javascript
• TEMP=/home/daverapin/projects/gleam/rally-scoreboard-example/tmp gleam test --target erlang
• node test/boundary_guard_test.mjs
• node test/ws_result_smoke.mjs
• npm run test:browser
