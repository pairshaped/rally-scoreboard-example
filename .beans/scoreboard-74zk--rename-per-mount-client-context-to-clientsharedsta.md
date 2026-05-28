---
# scoreboard-74zk
title: Rename per-Mount client context to ClientSharedState
status: todo
type: task
priority: normal
created_at: 2026-05-28T14:36:18Z
updated_at: 2026-05-28T14:36:18Z
parent: scoreboard-v94b
blocked_by:
    - scoreboard-2uax
---

## What to build

Rename the per-Mount boot state from client context vocabulary to ClientSharedState vocabulary in app and generated code. The type lives in the shared target because SSR and browser hydration use the same shape.

## Acceptance criteria

- [ ] Shared per-Mount types are named ClientSharedState, with module names matching the ADR vocabulary.
- [ ] Server loaders use client_shared_state_loader naming.
- [ ] Client-side browser code uses ClientSharedState naming for init, update, and hydration state.
- [ ] Generated setup and SSR comments use ClientSharedState vocabulary.
- [ ] AuthenticationContext remains separate from ClientSharedState.
- [ ] Existing hydration behavior still works for public and admin mounts.
- [ ] Generated snapshots are updated.
- [ ] Full test suite passes.

## Blocked by

- scoreboard-2uax

## Notes for Claude

Do not collapse AuthenticationContext into ClientSharedState. AuthenticationContext is shared identity. ClientSharedState is Mount-specific shell/page state derived from route, authentication facts, authorization facts, and app data.
