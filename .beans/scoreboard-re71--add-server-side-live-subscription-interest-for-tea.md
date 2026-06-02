---
# scoreboard-re71
title: Add server-side live subscription interest for team pages
status: todo
type: task
priority: high
tags:
    - live-updates
    - websockets
    - routing
    - prerequisite
created_at: 2026-06-02T11:54:09Z
updated_at: 2026-06-02T11:57:20Z
parent: scoreboard-d0g1
blocking:
    - scoreboard-d0g1
---

## Problem

Team detail pages currently receive every global `GameUpdated` push. The shared team view can ignore unrelated games locally, but that still means the connection receives events it did not express interest in. That leaks runtime shape into page reducers and makes future route-specific subscriptions harder to reason about.

## Direction

Model subscription interest on the server side for each WebSocket connection.

Likely shape:

- Keep the global app topic for events that every client should see.
- Add route or entity topics through the existing `server/topics` wrapper around Erlang `pg`.
- Let a client connection join team-specific topics such as `team:TOR` or `team:toronto-towers` when it loads `/teams/:slug`.
- Leave or change topics when navigation changes so stale page interests stop receiving pushes.
- Broadcast `GameUpdated` to the game topic and the two assigned team topics, while preserving global broadcasts only where the product actually wants global fanout.
- Decide whether subscription interest should be a first-class `ToServer` message, generated route boot metadata, or app-owned socket control frame.

## Acceptance Criteria

- A `/teams/:slug` connection receives `GameUpdated` only for games where that team is home or away.
- Navigating from one team page to another updates server-side subscription interest without requiring a socket reconnect.
- Game list, standings, game detail, and admin pages keep receiving the live updates they need.
- Topic membership is cleaned up on socket close and route changes.
- The implementation is covered by a focused regression test or a socket-level smoke test.

## Relevant Files

- `src/server/ws.gleam`
- `src/server/topics.gleam`
- `src/server_topics_ffi.erl`
- `src/client/api.gleam`
- `src/client/api_ffi.mjs`
- `src/client/to_client.gleam`
- `src/public/pages/teams/slug_.gleam`
- `src/public_app.gleam`
- `src/api/to_server.gleam`
- `src/api/to_client.gleam`


## Priority Note

Resolve this before the refactoring/unwind work. Subscription interest is part of the runtime contract: if the refactor lands first, it may cement a global-push shape that team/game/page-specific live updates then have to fight.
