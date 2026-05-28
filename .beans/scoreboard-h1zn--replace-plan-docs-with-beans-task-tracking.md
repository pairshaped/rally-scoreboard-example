---
# scoreboard-h1zn
title: Replace plan docs with Beans task tracking
status: completed
type: task
priority: high
created_at: 2026-05-28T14:36:54Z
updated_at: 2026-05-28T14:37:43Z
---

## What to build

Make Beans the source of truth for implementation task tracking instead of keeping mutable plan documents in docs.

## Acceptance criteria

- [x] Remove the generator chase target plan doc from active docs.
- [x] Update any references that point agents at the plan doc for task tracking.
- [x] Keep ADRs as design records, not task ledgers.
- [x] Beans check passes.

## Blocked by

None - can start immediately.

## Summary of Changes

Deleted docs/generator-chase-target-plan.md, updated README.md to point implementation work at Beans, and removed the deleted plan doc reference from the active Beans epic. ADRs remain the design record.
