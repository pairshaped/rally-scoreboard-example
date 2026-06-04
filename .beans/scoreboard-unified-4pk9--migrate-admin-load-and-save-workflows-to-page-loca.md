---
# scoreboard-unified-4pk9
title: Migrate admin load and save workflows to page-local contracts
status: in-progress
type: feature
priority: high
tags:
    - rally
    - chase
created_at: 2026-06-04T03:38:31Z
updated_at: 2026-06-04T16:08:35Z
parent: scoreboard-unified-wm8p
blocked_by:
    - scoreboard-unified-adc2
---

## What to build

Move the admin games workflow off the temporary root API bridge. Admin games should define page/workflow-local load and save contracts, including result handling for score updates, finalization, and any future form-like saves.

Save behavior should follow ADR 0010: a correlated result with the initiating page's needed payload, plus a broadcast to other subscribed connections when the saved data is also a live event.

## Plan outline

- Define admin page-local `ServerMsg` and result types for loading games and saving score/finalization changes.
- Generate or use generated page-local save RPC glue with `on_result` callbacks.
- Keep ordinary form/save flows low ceremony: `Created(Result(Item, SaveError))` or equivalent page-owned messages should work without extra request pointer ceremony.
- Exclude the origin connection from `GameUpdated` broadcasts while still broadcasting to other subscribed admin connections.
- Remove admin load/save dependence on root `ToServer`, `ToClient`, and root admin summary/update types.
- Extend smoke tests to prove the origin receives the save result payload and peer admin connections receive the broadcast.

## Acceptance criteria

- [ ] Admin games load uses a page-local contract.
- [ ] Score adjustment uses a page-local save contract with correlated result handling.
- [ ] Finalization uses a page-local save contract with correlated result handling.
- [ ] The initiating admin connection updates from the save result payload, while other subscribed admin connections receive the live broadcast.
- [ ] Root admin API/domain types are no longer needed for this workflow.

## Blocked by

- Rally load RPC generation for page-local contracts.

- Decision note: admin save ack payloads belong in the admin page contract, not a new shared module. Cross-page live broadcast events live in `src/broadcasts.gleam`, because public and admin pages all consume game update events.
