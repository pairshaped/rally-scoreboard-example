---
# scoreboard-okk8
title: Investigate redundant admin mutation response frame
status: completed
type: task
priority: normal
tags:
    - protocol
    - websocket
    - admin
created_at: 2026-06-02T10:34:31Z
updated_at: 2026-06-02T17:50:59Z
---

## Problem

Clicking a + score button in admin appears to produce three websocket messages:

1. ToServer UpdateScore from the browser.
2. A direct save result frame containing `Result(Nil, List(ApiSaveError))`.
3. A broadcast push frame containing `GameUpdated(GameSnapshot)`.

The second frame is still useful for success or validation errors, but it should not carry domain data. The broadcast carries the state update.

Example observed frames from a + click:

- request: g2gDbQAAAAthZG1pbi9nYW1lc2EBaAV3DHVwZGF0ZV9zY29yZWEDYQFhAm0AAAAETGl2ZQ==
- save result: encoded `Result(Nil, List(ApiSaveError))`
- broadcast: AAAAAAGDaAJ3DGdhbWVfdXBkYXRlZGgHdw1nYW1lX3NuYXBzaG90YQNoBHcEdGVhbW0AAAADQk9TbQAAABBCb3N0b24gQmxpenphcmRzbQAAABBib3N0b24tYmxpenphcmRzaAR3BHRlYW1tAAAAA0xBS20AAAATTG9zIEFuZ2VsZXMgS25pZ2h0c20AAAATbG9zLWFuZ2VsZXMta25pZ2h0c2EBYQJoAncEbGl2ZW0AAAAETGl2ZQ==

## Direction

UpdateScore and MarkFinal use a save result for success or failure. Successful saves send `Ok(Nil)` and do not include game data.

Errors do not travel through the broadcast push path. The broadcast push remains the shared state update channel.

## Acceptance criteria

- The message sequence is decoded and documented in completion notes.
- If the result is redundant, remove it without losing admin score updates, public live updates, or error handling.
- If the result is necessary, document why and make sure tests cover that reason.
- Browser smoke or protocol tests cover admin + score behavior after the decision.

## Completed notes

The redundant domain response was removed. Save requests now receive a direct `Result(Nil, List(ApiSaveError))` result, and successful score/result changes publish `GameUpdated(GameSnapshot)` through the normal `ToClient` app-data path.

Validation run before completion:

- `gleam format && gleam test`
- `gleam build --target javascript`
- `gleam build --target erlang`
