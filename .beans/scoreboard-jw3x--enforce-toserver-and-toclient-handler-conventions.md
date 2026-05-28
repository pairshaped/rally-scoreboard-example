---
# scoreboard-jw3x
title: Enforce ToServer and ToClient handler conventions
status: completed
type: task
priority: normal
created_at: 2026-05-28T14:36:05Z
updated_at: 2026-05-28T15:35:53Z
parent: scoreboard-v94b
blocked_by:
    - scoreboard-0qn9
---

## What to build

Make the generator fail clearly when app code drifts from the documented handler conventions. Server ToServer handlers and client ToClient handlers should be convention-driven instead of ad hoc.

## Acceptance criteria

- [x] ToServer constructors map to exactly one server handler named by snake_case constructor name.
- [x] ToClient constructors map to client handlers named by snake_case constructor name.
- [x] Handlers receive constructor fields as named arguments rather than whole ToServer or ToClient values.
- [x] Missing required handlers fail generation with a useful message.
- [x] Wrong handler signatures fail generation when possible, or produce a tight generated compile failure.
- [x] Generated comments document the convention in server dispatch and client to_client modules.
- [x] Tests cover at least one missing client handler and one wrong client handler signature.
- [x] Full test suite passes.

## Summary of Changes

Enhanced generated dispatch comments in all 4 dispatch modules to explicitly document the handler naming convention that existed at completion time. Follow-up bean `scoreboard-qaqh` updates this to the ADR 0006 convention: server page `init` is the SSR boot hook, and all `ToServer` constructors use explicit snake_case handlers.

Added 7 handler convention tests to `scoreboard_app_test.gleam`:
- `public_to_client_dispatch_uses_snake_case_handler_names_test` — verifies each handler call uses the correct snake_case name
- `admin_to_client_dispatch_uses_snake_case_handler_names_test` — same for admin
- `public_server_dispatch_uses_handler_conventions_test` — verified the page-load handler convention that existed at completion time and other-Mount command rejection
- `admin_server_dispatch_uses_handler_conventions_test` — verifies command handlers use snake_case names with labeled args and other-Mount commands are rejected
- `to_client_dispatch_never_calls_receive_function_test` — no generic `receive()` shim exists
- `to_client_dispatch_explicitly_handles_each_constructor_test` — every constructor with a handler has an explicit case branch, so a missing handler would be a compile error
- `to_client_handlers_receive_labeled_args_not_whole_message_test` — handler functions use `label var: Type` syntax, not positional args

Updated 3 Birdie snapshots for dispatch comment changes. Full test suite: 34 shared, 4 client, 89 server (all passing).
