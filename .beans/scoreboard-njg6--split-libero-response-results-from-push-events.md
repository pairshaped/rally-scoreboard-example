---
# scoreboard-njg6
title: Split Libero acks from app data
status: completed
type: task
priority: high
tags:
    - libero
    - api-contract
    - live-updates
created_at: 2026-06-02T13:04:17Z
updated_at: 2026-06-02T17:50:59Z
parent: scoreboard-d0g1
blocking:
    - scoreboard-re71
    - scoreboard-okk8
---

## Problem

Scoreboard currently uses one global `ToClient` vocabulary for both app data and no-data operation outcomes. That has produced drift:

- Save acknowledgements are named and shaped like domain events (`ScoreUpdateSaved`, `ResultSaved`).
- `GamesLoadFailed` is reused for game, team, and standings failures.
- Broadcast planning has to inspect response-shaped constructors and decide which ones are actually publishable.
- The initiating admin receives both a save ack and a `GameUpdated` payload that can update the same row.

Because this repo is exercising Libero design, we should not treat the current one-root response shape as fixed.

## Direction

Adjust Libero and Scoreboard so load/save acks are separate from app data.

Libero should generate the ack error types:

```gleam
pub type ApiLoadError {
  ApiLoadError(message: String)
}

pub type ApiSaveError {
  ApiSaveError(field: Option(String), message: String)
}
```

The generated ack payloads are:

```gleam
Result(Nil, List(ApiLoadError))
Result(Nil, List(ApiSaveError))
```

The success side must remain `Nil`: the ack carries no domain data.

`ToClient` remains the authored server-to-client app-data vocabulary. It can carry load data and live update data. This keeps the name accurate and avoids a second load-response enum.

Request flow:

```text
Load success:
ToServer.LoadGames
  -> Ok(Nil)
  -> ToClient.GamesLoaded(games)

Load failure:
ToServer.LoadGames
  -> Error([ApiLoadError("Could not load games")])

Save success:
ToServer.UpdateScore
  -> Ok(Nil)
  -> ToClient.GameUpdated(game)

Save failure:
ToServer.UpdateScore
  -> Error([ApiSaveError(field: Some("home_score"), message: "Must be 0 or greater")])
```

The arrow notation describes message sequence, not nesting. The `Result(Nil, errors)` ack and `ToClient` messages are separate values.

## Acceptance Criteria

- Direct request ack is decoded as `Result(Nil, List(ApiLoadError))` or `Result(Nil, List(ApiSaveError))`, not as `ToClient`.
- Successful ack is `Ok(Nil)` and carries no domain data.
- `ToClient` remains the server-to-client app-data vocabulary for load data and live updates.
- `GamesLoadFailed` and similarly reused failure constructors are removed or replaced by `Error([...])` ack values.
- Save responses do not echo the original request payload and do not carry updated domain objects.
- Save acknowledgements such as `ScoreUpdateSaved` and `ResultSaved` are removed or replaced by `Ok(Nil)`.
- Domain changes continue to be sent as `ToClient` app data, for example `GameUpdated(GameSnapshot)`.
- Scoreboard tests verify `Result(Nil, List(ApiSaveError))` decoding and `ToClient` decoding independently.
- Libero generation supports the generated ack error types and generic `Result(...)` ack payloads without hand-written tracer glue.

## Notes

The old `LoadResult(data, error)` / `SaveResult(error)` direction was rejected because it created extra user-authored response types and moved load vocabulary rather than simplifying it.

The ack concept does not need a custom `Ack`, `Outcome`, `LoadResult`, `SaveResult`, or app-owned `Result` type. It should use Gleam's built-in `Result(Nil, List(error))` shape directly.

There are two generated ack error types:

- `ApiLoadError` for load failures
- `ApiSaveError(field: Option(String), message: String)` for save or validation failures

Keep those error types small and protocol-oriented. Do not put domain payloads in them.

Do not put `ApiLoadError` or `ApiSaveError` in user-authored `src/api` code. Libero owns them and emits them into generated code.

Do not add `request_id` to the public generated request or ack helper surface. The client and server are running TEA-style update loops; ack payloads are handled as messages in that flow rather than as correlated RPC promises.

## Completed notes

Libero now generates direct ack helpers and the ack error types.

Scoreboard uses:

- `Result(Nil, List(ApiLoadError))` for load acks
- `Result(Nil, List(ApiSaveError))` for save acks
- `ToClient` only for load data and live app data such as `GamesLoaded` and `GameUpdated`

Validation run before completion:

- Libero: `gleam format && gleam test && node test/js/generated_codec_test.mjs`
- Scoreboard: `gleam format && gleam test`
- Scoreboard: `gleam build --target javascript`
- Scoreboard: `gleam build --target erlang`
- `beans check`

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
