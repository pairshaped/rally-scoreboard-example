---
# scoreboard-qaqh
title: Adopt page init and init_requests convention
status: todo
type: task
priority: high
created_at: 2026-05-28T17:31:16Z
updated_at: 2026-05-28T17:31:16Z
parent: scoreboard-v94b
blocked_by:
    - scoreboard-74zk
---

## What to build

Align Scoreboard with the page boot convention recorded in ADR 0006 and ADR 0007.

Shared page modules declare first-render server requests with `init_requests() -> List(ToServer)`. Generated SSR executes those requests into `ToClient` hydration data. Generated client init sends those requests when hydration is absent. Client and server page modules only expose `init(...)` when they need custom behavior.

## Acceptance criteria

- [ ] Shared pages that need first-render data expose `init_requests() -> List(ToServer)`.
- [ ] Each `init_requests` function has a function comment explaining that it is shared boot wiring consumed by generated SSR and generated client init.
- [ ] Pages with no custom boot behavior omit client and server `init`.
- [ ] Custom client `init(...)` uses SSR-hydrated model state to decide whether to send `init_requests`.
- [ ] Custom server `init(...) -> List(ToServer)` augments or filters boot requests before generated SSR execution.
- [ ] Every `ToServer.Load*` constructor has an explicit snake_case server handler such as `load_games` or `load_admin_games`.
- [ ] Page-data handlers returned by `init_requests` use the direct `List(ToClient)` signature and live dispatch sends those values without changing backend model.
- [ ] Generated SSR executes shared `init_requests` when no server `init` exists.
- [ ] Generated SSR executes custom server `init` requests when server `init` exists.
- [ ] Generated live dispatch maps `ToServer` constructors to the explicit snake_case handlers, not to page `init`.
- [ ] Generated comments near SSR/client init execution explain that `init_requests` is the source of truth and target `init` hooks must call it when it is non-empty.
- [ ] Generated comments and convention tests describe and enforce this split.
- [ ] Tests verify every shared page `init_requests` function has the required function comment.
- [ ] Tests verify generated SSR and client init code include comments describing how `init_requests` is consumed.
- [ ] Tests verify the generated dispatch shape still requires `init_requests` `ToServer` constructors to have explicit handler calls in the generated code.
- [ ] Tests verify SSR executes `init_requests` into hydration `ToClient` values and live dispatch sends the same handler result over WebSocket.
- [ ] Existing SSR hydration and live navigation behavior still pass.

## Notes for Claude

Do not reintroduce SSR-specific duplicate handlers. `init_requests` is the shared request declaration and source of truth. Target `init` functions are optional customization hooks. `LoadGames -> load_games` remains the handler convention.

Add real function comments for `init_requests`, not vague file comments. The comment should say that generated SSR executes the returned `ToServer` values locally and embeds the resulting `ToClient` values for hydration, while generated client init sends the same requests over WebSocket only when hydration has not already populated the page model.

Scoreboard currently has checked-in generated output, not a real generator implementation. Do not claim generator failure behavior is implemented yet. The future generator rejection requirements live in ADR 0006.
