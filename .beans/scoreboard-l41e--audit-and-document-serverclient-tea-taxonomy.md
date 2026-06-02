---
# scoreboard-l41e
title: Audit and document server/client TEA taxonomy
status: todo
type: task
priority: high
tags:
    - architecture
    - taxonomy
    - adr
    - tea
created_at: 2026-06-02T18:02:31Z
updated_at: 2026-06-02T18:02:31Z
parent: scoreboard-d0g1
blocking:
    - scoreboard-d0g1
---

## Problem

We are converging on a server TEA plus client TEA runtime shape, but the project taxonomy is not explicit enough yet. Recent protocol work exposed name drift around request, response, ack, app data, `ToServer`, `ToClient`, generated types, user-authored types, and live pushes.

If those names stay implicit, ADRs and generated code will keep pulling the design back toward RPC or server-components vocabulary by accident.

## Direction

Audit the current taxonomy across code, beans, docs, and ADRs, then write down the canonical terms explicitly.

The target mental model should look similar to the server-components approach in `../scoreboard-sc`: the server owns a real update loop and can produce effects from app messages. The difference is that this app has a real client TEA runtime, not VDOM diff delivery. Server output should hydrate and update the client through ETF values that the client can own normally.

Ignore the `scoreboard-sc` page-local wire type approach for this project. We are keeping root-level API/domain types because page-local wire types would complicate the ETF layer and namespace-stripped constructor uniqueness too much.

The audit should compare:

- current names in source code
- current names in beans
- current names in ADRs and docs
- intended names for the runtime taxonomy
- `../scoreboard-sc` vocabulary where it helps as a comparison

## Taxonomy To Capture

At minimum, decide and document canonical meanings for:

- `ToServer`: browser-to-server app message vocabulary
- `ToClient`: server-to-browser app data vocabulary
- load ack: `Result(Nil, List(ApiLoadError))`
- save ack: `Result(Nil, List(ApiSaveError))`
- `ApiLoadError`: generated Libero ack error type with `message: String`
- `ApiSaveError`: generated Libero ack error type with `field: Option(String), message: String`
- app data
- boot data
- hydration data
- live push
- response frame
- ack frame or ack payload
- generated API type versus user-authored API/domain type
- server TEA message/update/effect boundaries
- client TEA message/update/effect boundaries

## Acceptance Criteria

- The current taxonomy is inventoried from source, docs, beans, and ADRs.
- Conflicting or overloaded terms are listed with a proposed resolution.
- ADRs are updated so the canonical names are explicit taxonomy, not scattered usage.
- The docs clearly distinguish generated Libero protocol helpers from user-authored API/domain types.
- The docs clearly distinguish server TEA from client TEA and from server-components-style VDOM diff delivery.
- The docs explicitly state that page-local wire types are out of scope for this project.
- `beans check` passes.

## Relevant Files

- `docs/adr/*.md`
- `docs/unified-target-source.md`
- `.beans/*.md`
- `src/api/**`
- `src/generated/api/**`
- `src/server/api.gleam`
- `src/server/ws.gleam`
- `src/client/api.gleam`
- `src/client/to_client.gleam`
- `../scoreboard-sc`
