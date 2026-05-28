---
# scoreboard-jw3x
title: Enforce ToServer and ToClient handler conventions
status: todo
type: task
priority: normal
created_at: 2026-05-28T14:36:05Z
updated_at: 2026-05-28T14:36:05Z
parent: scoreboard-v94b
blocked_by:
    - scoreboard-0qn9
---

## What to build

Make the generator fail clearly when app code drifts from the documented handler conventions. Server ToServer handlers and client ToClient handlers should be convention-driven instead of ad hoc.

## Acceptance criteria

- [ ] ToServer constructors map to exactly one server handler named by snake_case constructor name.
- [ ] ToClient constructors map to client handlers named by snake_case constructor name.
- [ ] Handlers receive constructor fields as named arguments rather than whole ToServer or ToClient values.
- [ ] Missing required handlers fail generation with a useful message.
- [ ] Wrong handler signatures fail generation when possible, or produce a tight generated compile failure.
- [ ] Generated comments document the convention in server dispatch and client to_client modules.
- [ ] Tests cover at least one missing client handler and one wrong client handler signature.
- [ ] Full test suite passes.

## Blocked by

- scoreboard-0qn9

## Notes for Claude

A generic receive function is not a framework handler. Avoid compatibility shims that let both receive and constructor-named handlers work; that would keep the spaghetti door open.
