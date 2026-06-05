---
# scoreboard-unified-api1
title: Investigate broadcast sender topic targeting
status: todo
type: task
priority: normal
tags:
    - rally
    - broadcasts
    - topics
created_at: 2026-06-05T18:00:00Z
updated_at: 2026-06-05T18:00:00Z
parent: scoreboard-unified-p5sh
---

## What to investigate

`src/app_api.gleam` builds the `BroadcastGameUpdated` payload after an admin mutation, while `src/app_ws.gleam` sends that payload to the universal `"app"` topic. The payload construction is app-owned and reasonable; the questionable part is that the sender-side topic choice is disconnected from the changed game and currently routes everything through one root topic.

Investigate whether broadcast construction should return topic targets with the event, or whether the caller should derive topic targets from the fresh game snapshot before sending. The end state should support page-owned topic subscriptions without requiring root page-constructor dispatch.

## Questions to answer

- Should `app_api.game_updated_broadcast` return only `broadcasts.Event`, or a domain value that includes affected topics?
- Should topic targeting live beside payload construction, beside the mutation caller in `app_ws`, or behind a Rally helper?
- What topics should a game update target: all games, one game id, home team, away team, admin games, or some combination?
- How should topic names be represented so pages and senders cannot drift?
- Does this need a shared app-owned topic module, page-owned topic declarations, or generated Rally topic helpers?

## Acceptance criteria

- The investigation identifies the sender-side topic source of truth.
- Broadcast payload shape remains separate from correlated mutation results.
- Root `broadcasts.gleam` can keep app-wide event payload types.
- Sender-side topic selection no longer depends on a universal `"app"` topic.
- The choice fits page-owned topic subscriptions from `scoreboard-unified-p5sh`.

## Validation

- `gleam build --target erlang`
- `gleam build --target javascript`
- `node test/ws_result_smoke.mjs`
