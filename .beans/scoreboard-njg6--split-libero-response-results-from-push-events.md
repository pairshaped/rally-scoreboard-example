---
# scoreboard-njg6
title: Split Libero response results from push events
status: todo
type: task
priority: high
tags:
    - libero
    - api-contract
    - live-updates
created_at: 2026-06-02T13:04:17Z
updated_at: 2026-06-02T13:04:17Z
parent: scoreboard-d0g1
blocking:
    - scoreboard-re71
    - scoreboard-okk8
---

## Problem

Scoreboard currently uses one global `ToClient` vocabulary for both direct request responses and server-pushed events. That has produced drift:

- Save acknowledgements are named and shaped like domain events (`ScoreUpdateSaved`, `ResultSaved`).
- `GamesLoadFailed` is reused for game, team, and standings failures.
- Broadcast planning has to inspect response-shaped constructors and decide which ones are actually publishable.
- The initiating admin receives both a save ack and a `GameUpdated` payload that can update the same row.

Because this repo is exercising Libero design, we should not treat the current one-root response shape as fixed.

## Direction

Adjust Libero and Scoreboard so `ToClient` means server-pushed events only. Direct responses should be operation-specific response payloads generated from the `ToServer` request shape.

Introduce explicit generic result envelopes:

```gleam
pub type LoadResult(data, error) {
  LoadResultSucceeded(data)
  LoadResultFailed(error)
}

pub type SaveResult(error) {
  SaveResultSucceeded
  SaveResultFailed(error)
}
```

The success data remains the existing wired domain type for each load. Save responses carry only the save outcome and validation/error information, not the updated domain object. Domain changes are published separately as push events.

Example target shape:

- `LoadGames -> LoadResult(List(PublicGameSummary), LoadError)`
- `LoadGame -> LoadResult(GameDetail, LoadError)`
- `LoadStandings -> LoadResult(List(StandingRow), LoadError)`
- `LoadTeam -> LoadResult(TeamDetail, LoadError)`
- `LoadAdminGames -> LoadResult(List(AdminGameSummary), LoadError)`
- `UpdateScore -> SaveResult(SaveError)`
- `MarkFinal -> SaveResult(SaveError)`
- `CorrectResult -> SaveResult(SaveError)`

Then `ToClient` can shrink toward push-only events such as:

```gleam
pub type ToClient {
  GameUpdated(game: GameSnapshot)
}
```

## Acceptance Criteria

- Direct response frames are decoded using the response type for the request they answer, not the global `ToClient` push root.
- `ToClient` no longer contains save acknowledgements or load responses.
- `GamesLoadFailed` and similarly reused failure constructors are removed or replaced by typed load/save result errors.
- Save responses do not echo the original request payload and do not carry updated domain objects.
- `GameUpdated` remains a push event and can be broadcast by topic once subscription interest is implemented.
- Scoreboard tests verify response decoding and push decoding independently.
- Libero generation supports the new request-specific response roots without hand-written tracer glue.

## Notes

`SaveResult` should be explicit rather than modeled as `Option(SaveError)`. `Option` makes absence mean success, which is compact but too clever for a reusable transport shape.

This should land before server-side subscription interest, because topic routing should only plan around push events, not direct response acknowledgements.

## Relevant Files

- `../libero`
- `gleam.toml`
- `src/api/to_server.gleam`
- `src/api/to_client.gleam`
- `src/api/domain/**`
- `src/generated/api/**`
- `src/server/api.gleam`
- `src/server/ws.gleam`
- `src/client/api.gleam`
- `src/client/to_client.gleam`
- `src/public_app.gleam`
- `src/admin_app.gleam`
- `test/scoreboard_unified_test.gleam`
- `test/browser_smoke.mjs`

