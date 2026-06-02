---
# scoreboard-okk8
title: Investigate redundant admin mutation response frame
status: todo
type: task
priority: normal
tags:
    - protocol
    - websocket
    - admin
created_at: 2026-06-02T10:34:31Z
updated_at: 2026-06-02T10:34:31Z
---

## Problem

Clicking a + score button in admin appears to produce three websocket messages:

1. ToServer UpdateScore from the browser.
2. A server response frame containing ScoreUpdateSaved/AdminGameDetail.
3. A broadcast push frame containing GameUpdated/GameSnapshot.

The second frame may be an avoidable acknowledgement if the broadcast already carries enough state for the initiating admin and public clients. It may also still be useful if admin needs request-scoped confirmation, validation errors, or a different payload shape from public live updates.

Example observed frames from a + click:

- request: g2gDbQAAAAthZG1pbi9nYW1lc2EBaAV3DHVwZGF0ZV9zY29yZWEDYQFhAm0AAAAETGl2ZQ==
- response/ack: AAAAAAGDaAJ3EnNjb3JlX3VwZGF0ZV9zYXZlZGgIdxFhZG1pbl9nYW1lX2RldGFpbGEDbQAAAANCT1NtAAAAA0xBS2EBYQJoAncEbGl2ZW0AAAAETGl2ZW0AAAAETGl2ZQ==
- broadcast: AAAAAAGDaAJ3DGdhbWVfdXBkYXRlZGgHdw1nYW1lX3NuYXBzaG90YQNoBHcEdGVhbW0AAAADQk9TbQAAABBCb3N0b24gQmxpenphcmRzbQAAABBib3N0b24tYmxpenphcmRzaAR3BHRlYW1tAAAAA0xBS20AAAATTG9zIEFuZ2VsZXMgS25pZ2h0c20AAAATbG9zLWFuZ2VsZXMta25pZ2h0c2EBYQJoAncEbGl2ZW0AAAAETGl2ZQ==

## Direction

Trace UpdateScore and MarkFinal handling through server/api.gleam, server/ws.gleam, and client/to_client.gleam. Decide whether the initiating admin can rely on the broadcast payload, or whether admin-specific confirmation/error payloads need to remain separate.

## Acceptance criteria

- The message sequence is decoded and documented in completion notes.
- If the ack is redundant, remove it without losing admin score updates, public live updates, or error handling.
- If the ack is necessary, document why and make sure tests cover that reason.
- Browser smoke or protocol tests cover admin + score behavior after the decision.
