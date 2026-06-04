---
# scoreboard-unified-ak07
title: Release Marmot generated-directory discovery and remove the path dependency
status: todo
type: task
priority: normal
tags:
    - rally
    - chase
    - sql
created_at: 2026-06-04T03:38:31Z
updated_at: 2026-06-04T03:38:31Z
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

- [ ] Scoreboard no longer relies on an uncommitted local Marmot scanner fix.
- [ ] `gleam run -m marmot` does not scan or warn about `src/generated/sql`.
- [ ] Authored SQL remains colocated beside owning pages/workflows.
- [ ] Generated SQL modules remain under generated SQL output.
- [ ] Dependency and manifest changes are committed.

## Blocked by

None - can start immediately.
