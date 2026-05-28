---
# scoreboard-fmsn
title: Convert admin ToClient handling to page mini-updates
status: completed
type: task
priority: high
created_at: 2026-05-28T19:36:44Z
updated_at: 2026-05-28T19:50:40Z
parent: scoreboard-nwoq
blocked_by:
    - scoreboard-tdxl
---

## What to build

Convert the admin Mount to the same page mini-update contract established by the public Mount.

Admin page modules should keep real local `Msg` constructors for browser-originated events such as form edits, create-game clicks, score adjustments, and finalization. Server-emitted `ToClient` values should update the admin page model directly through constructor-named handlers instead of proxying through local messages.

## Acceptance criteria

- [ ] Admin page `ToClient` handlers take the page `Model` plus constructor fields and return `#(Model, Effect(Msg))`.
- [ ] Admin local page `Msg` keeps only browser-originated actions such as `CreateGame`, `UpdateHomeCode`, `UpdateAwayCode`, `AdjustHome`, `AdjustAway`, and `MarkFinal`.
- [ ] Admin local page `Msg` does not contain protocol-shaped constructors that only mirror `AdminGamesLoaded`, `GameCreated`, `ScoreUpdateSaved`, `ResultSaved`, `GameScoreUpdated`, or `AdminError`.
- [ ] Generated admin `to_client` dispatch owns an admin page-model bundle, applies `ToClient` values to active admin page handlers, stores returned page models, and batches page effects.
- [ ] `scoreboard_admin_client.gleam` receives raw shared `ToClient` values and delegates server-event handling to generated admin `to_client` dispatch.
- [ ] Admin page-originated effects still send the correct `ToServer` commands for create game, score update, and mark final.
- [ ] Shared, client, and server tests pass.

## Blocked by

- scoreboard-tdxl
