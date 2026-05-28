---
# scoreboard-74zk
title: Rename per-Mount client context to ClientSharedState
status: completed
type: task
priority: normal
created_at: 2026-05-28T14:36:18Z
updated_at: 2026-05-28T16:32:04Z
parent: scoreboard-v94b
blocked_by:
    - scoreboard-2uax
---

## What to build

Rename the per-Mount boot state from client context vocabulary to ClientSharedState vocabulary in app and generated code. The type lives in the shared target because SSR and browser hydration use the same shape.

## Acceptance criteria

- [x] Shared per-Mount types are named ClientSharedState, with module names matching the ADR vocabulary.
- [x] Server loaders use client_shared_state_loader naming.
- [x] Client-side browser code uses ClientSharedState naming for init, update, and hydration state.
- [x] Generated setup and SSR comments use ClientSharedState vocabulary.
- [x] AuthenticationContext remains separate from ClientSharedState.
- [x] Existing hydration behavior still works for public and admin mounts.
- [x] Generated snapshots are updated.
- [x] Full test suite passes.

## Summary of Changes

Renamed all per-Mount client context vocabulary to ClientSharedState across app and generated code:

5 files renamed: `shared/{public,admin}/client_context.gleam` -> `client_shared_state.gleam`, `server/{public,admin}/client_context_loader.gleam` -> `client_shared_state_loader.gleam`, `client/test/client_context_smoke_ffi.mjs` -> `client_shared_state_smoke_ffi.mjs`.

Type renames: `PublicClientContext` -> `PublicClientSharedState`, `AdminClientContext` -> `AdminClientSharedState`. Function/variable renames: `read_client_context()` -> `read_client_shared_state()`, `readClientContext()` -> `readClientSharedState()`, `client_context_base64` -> `client_shared_state_base64`, `client_context_loader` -> `client_shared_state_loader`. Window variable: `__RUNTIME_CLIENT_CONTEXT__` -> `__RUNTIME_CLIENT_SHARED_STATE__`. Codec atoms and protocol atoms FFI updated.

Updated 8 generated source files, 2 client roots, 2 test files, and 8 Birdie snapshots. AuthenticationContext remains separate from ClientSharedState.

Full test suite: 34 shared, 4 client, 89 server (all passing).
