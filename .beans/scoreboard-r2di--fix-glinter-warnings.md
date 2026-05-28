---
# scoreboard-r2di
title: Fix glinter warnings
status: todo
type: task
priority: low
created_at: 2026-05-28T16:32:39Z
updated_at: 2026-05-28T16:32:39Z
parent: scoreboard-v94b
blocked_by:
    - scoreboard-74zk
    - scoreboard-zgoz
---

## What to build

Run glinter and fix the reported warnings in the codebase. Prefer improving the code to suppressing warnings. Only ignore, exclude, or disable a warning when there is a clear reason and document that reason near the suppression.

## Acceptance criteria

- [ ] Run glinter and record the warning categories found.
- [ ] Fix warnings by changing code where practical.
- [ ] Do not add blanket ignores or broad excludes.
- [ ] Any remaining suppression has a local explanation for why the warning is intentionally accepted.
- [ ] Full test suite passes.
- [ ] beans check passes.

## Blocked by

- scoreboard-74zk
- scoreboard-zgoz

## Notes for Claude

Do this after the active generator/page cleanup lands. Do not let lint cleanup obscure the structural migration diffs.
