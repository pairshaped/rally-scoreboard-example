---
# scoreboard-rlz8
title: Investigate admin mutation outcome ergonomics
status: todo
type: task
priority: normal
tags:
    - ergonomics
    - protocol
    - admin
created_at: 2026-05-30T20:46:52Z
updated_at: 2026-05-30T20:46:52Z
---

## Problem

Admin mutations in the sibling app still carry some server-component-inspired ergonomics pain: a single score action has to update server state, broadcast live state, send an action-specific acknowledgement, and update the initiating client model from multiple ToClient shapes.

Current admin score update flow:

1. `client/src/client/admin/pages/games.gleam` sends `ToServer.UpdateScore` from `AdjustHome` / `AdjustAway`.
2. `server/src/server/admin/pages/games.gleam` writes the score.
3. The server reloads a `GameSnapshot` row and calls `live_updates.broadcast(to_client.GameUpdated(...))`.
4. The same handler also sends `to_client.ScoreUpdateSaved(game:)` to the initiating socket.
5. The client handles both state-shaped messages: `game_updated` upserts from `GameSnapshot`, while `score_update_saved` upserts from `AdminGameDetail` and sets the notice.

The same pattern exists for finalization via `ResultSaved(game:)` plus `GameUpdated(game:)`.

This works, but it creates duplication:

- server handlers repeat mutate -> load snapshot -> broadcast -> send ack/error
- client page code has multiple handlers that convert different returned game shapes into the same `AdminGameSummary` list update
- the initiating admin socket appears to be in the same live-update group, so it can receive the state update through `GameUpdated` anyway
- action-specific success messages carry game payloads that may duplicate the live state payload

## Direction to investigate

Investigate whether admin mutations should split state updates from command acknowledgements:

- `GameUpdated(game:)` remains the canonical state-update event for public pages, admin observer tabs, and the initiating admin tab
- successful command acknowledgements become lightweight UI/status messages, for example `AdminNotice(message:)` or `CommandSucceeded(message:)`
- failures remain command-specific enough to display useful errors, likely `AdminError(reason:)` or a richer command error shape
- admin client model updates game state only in `game_updated`; success acknowledgements only update `notice`
- server handlers use a helper/convention for "write game, broadcast state, send notice"

This would preserve the explicit ToServer/ToClient architecture while borrowing the useful server-component lesson: the authored mutation workflow should read like one server-owned action, not as several manually synchronized protocol side effects.

## Current code references

- `shared/src/shared/api/to_server.gleam`: `UpdateScore`, `MarkFinal`, and `CorrectResult` commands.
- `shared/src/shared/api/to_client.gleam`: `GameUpdated`, `ScoreUpdateSaved`, `ResultSaved`, and `AdminError` events.
- `server/src/server/admin/pages/games.gleam`: `update_score`, `mark_final`, and `correct_result` repeat broadcast-plus-ack logic.
- `client/src/client/admin/pages/games.gleam`: `game_updated`, `score_update_saved`, and `result_saved` all update or convert game state.
- `server/src/generated/runtime/live_updates.gleam` and FFI join admin/public sockets into the live-update group and broadcast to local members.
- `server/test/root_api_ws_smoke.mjs` covers sender ack messages and observer/public `GameUpdated` broadcasts.

## Questions

- Does the initiating admin socket reliably receive its own `GameUpdated` broadcast? If yes, can state updates rely on that path?
- Is there any product reason for `ScoreUpdateSaved` and `ResultSaved` to carry full game payloads instead of just notice/status?
- Should success acknowledgements be generic (`AdminNotice`) or action-specific without payload (`ScoreUpdateSaved`, `ResultSaved` as zero/small payload events)?
- Would reducing action-specific payloads make socket traces clearer and smaller without weakening tests?
- Should the helper live in authored `server/admin/pages/games.gleam`, generated runtime effect helpers, or a small authored admin action helper?
- Can this be expressed as a convention without making handler generation more magical?

## Acceptance criteria

- Document the current admin mutation message sequence, including whether the sender receives both ack and `GameUpdated`.
- Recommend whether to keep `ScoreUpdateSaved` / `ResultSaved` as payload events, shrink them to notices, or replace them with a generic admin notice event.
- If implementing, preserve public and admin live updates after score changes and finalization.
- If implementing, reduce duplicated game-upsert code in `client/src/client/admin/pages/games.gleam`.
- If implementing, reduce repeated broadcast-plus-ack code in `server/src/server/admin/pages/games.gleam`.
- Add or update WebSocket smoke tests for sender ack, sender state update, admin observer update, and public update.
