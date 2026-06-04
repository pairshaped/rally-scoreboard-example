---
# scoreboard-unified-4pk9
title: Migrate admin load and save workflows to page-local contracts
status: todo
type: feature
priority: high
tags:
    - rally
    - chase
created_at: 2026-06-04T03:38:31Z
updated_at: 2026-06-04T03:38:31Z
parent: scoreboard-unified-wm8p
blocked_by:
    - scoreboard-unified-adc2
---

## What to build

Move the admin games workflow off the temporary root API bridge. Admin games should define page/workflow-local load and save contracts, including result handling for score updates, finalization, and any future form-like saves.

Save behavior should keep the current contract shape: a correlated result for the initiating request, plus self-broadcast for live updates when the saved data is also a subscribed event.

## Plan outline

- Define admin page-local `ServerMsg` and result types for loading games and saving score/finalization changes.
- Generate or use generated page-local save RPC glue with `on_result` callbacks.
- Keep ordinary form/save flows low ceremony: `Created(Result(Item, SaveError))` or equivalent page-owned messages should work without extra request pointer ceremony.
- Keep self-broadcast for `GameUpdated` style live update events.
- Remove admin load/save dependence on root `ToServer`, `ToClient`, and root admin summary/update types.
- Extend smoke tests to prove request result and self-broadcast both arrive when expected.

## Acceptance criteria

- [ ] Admin games load uses a page-local contract.
- [ ] Score adjustment uses a page-local save contract with correlated result handling.
- [ ] Finalization uses a page-local save contract with correlated result handling.
- [ ] Admin still receives its own broadcast for live game updates.
- [ ] Root admin API/domain types are no longer needed for this workflow.

## Blocked by

- Rally load RPC generation for page-local contracts.
