---
# scoreboard-v94b
title: Align page targets and ToClient handlers
status: todo
type: epic
priority: high
created_at: 2026-05-28T14:35:08Z
updated_at: 2026-05-28T14:37:22Z
---

## What to build

Bring Scoreboard into the three-target page model documented in the ADRs. Shared, client, and server page modules should mirror route paths where each target has code. Shared pages stay target-neutral. Client pages own browser behavior and constructor-named ToClient handlers. Server pages own load, data access, authorization, and ToServer handlers.

## Acceptance criteria

- [ ] Page modules mirror route paths across shared, client, and server targets.
- [ ] Shared page modules do not import shared/api/to_client or expose receive(event: ToClient).
- [ ] Client page modules own constructor-named ToClient handlers.
- [ ] Generated client dispatch uses to_client.gleam instead of receiver_dispatch.gleam.
- [ ] Generator comments and tests enforce ToServer and ToClient naming conventions.

## Notes

Source of truth: this Beans epic and its child beans. ADRs carry the intended design; Beans carries implementation work.
