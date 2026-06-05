---
# scoreboard-unified-p5sh
title: Move broadcast interest to page topics
status: todo
type: task
priority: high
tags:
    - rally
    - broadcasts
    - topics
created_at: 2026-06-05T18:00:00Z
updated_at: 2026-06-05T18:00:00Z
parent: scoreboard-unified-r0ut
---

## What to build

Move broadcast interest out of root page dispatch and into page-owned topic subscriptions. Root `broadcasts.gleam` may continue to define app-wide event payloads and message names, but pages should declare the topics they care about.

Generated Rally transport glue should join and leave topics as the active page changes. Senders should broadcast to the affected topics, not to a universal root `"app"` bucket that every browser receives.

## Current routing work to remove

- `app_ws.on_init` joins every websocket to `"app"`.
- `public_boot.apply_broadcast` and `admin_boot.apply_broadcast` match generated page constructors to decide which page receives `BroadcastGameUpdated`.
- `public_boot.apply_push` and `admin_boot.apply_push` use the module name `"app"` as the effective broadcast routing layer.

## Acceptance criteria

- Pages expose or declare their broadcast topic interest in page-local code.
- Generated/runtime websocket glue joins page topics on initial load and navigation, and leaves obsolete page topics when the active page changes.
- Broadcast senders publish to domain/page topics such as all games, one game, or one team.
- Root user code no longer matches generated page constructors to decide broadcast delivery.
- The initiating connection still updates from its correlated mutation result and does not receive its own broadcast for that mutation.

## Validation

- `gleam build --target erlang`
- `gleam build --target javascript`
- `node test/ws_result_smoke.mjs`
- Browser smoke or focused websocket smoke should prove multiple tabs converge and inactive pages are not used as the subscription decision point.
