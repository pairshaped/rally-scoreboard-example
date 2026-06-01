---
# scoreboard-edey
title: Investigate generated defaults for data-only client pages
status: todo
type: task
priority: normal
tags:
    - ergonomics
    - generation
    - client
created_at: 2026-05-30T20:48:06Z
updated_at: 2026-05-30T20:48:06Z
---

## Problem

The sibling app currently requires every routed client page to provide a client module with `Model`, `Msg`, `init`, `update`, and constructor-named ToClient handlers. For simple server-loaded pages this creates repeated boilerplate even when the page has no browser-originated messages or client-only effects.

Examples from current code:

- `client/src/client/public/pages/games.gleam` defines `NoOp`, `init`, and a single-branch `update`, then stores `GamesLoaded`, handles `GameUpdated`, and stores `GamesLoadFailed`.
- `client/src/client/public/pages/games/id_.gleam` defines the same `NoOp`/`init`/`update` boilerplate and custom `GameUpdated` merge logic.
- `client/src/client/public/pages/standings.gleam` defines the same boilerplate and mostly stores loaded rows, but also handles `PowerRankingsLoaded` by converting rows.
- `client/src/client/public/pages/teams/slug_.gleam` defines the same boilerplate and delegates live update logic to a shared helper.
- `client/src/client/admin/pages/games.gleam` is not data-only: it has browser-originated messages, client effects, score controls, and custom mutation outcomes.

The generated ToClient dispatch currently assumes each client page module exists and exposes `init()` and `update()`:

- `client/src/generated/public/to_client.gleam` calls `games.init()`, `standings.init()`, etc.
- `client/src/generated/admin/to_client.gleam` calls `games.init()`.

This makes even data-only pages pay the authored client-module tax.

## Direction to investigate

Investigate generated defaults for client page modules, scoped narrowly:

- always generate the boring `NoOp`/empty-update shape when a page has no browser-originated messages
- allow a page to omit authored `client/.../pages/foo.gleam` only when its ToClient handling is simple enough to generate safely
- require an authored client page module when the page has browser-originated messages, client-only effects, custom merge logic, custom notices, or derived state
- keep shared explicit ToServer/ToClient/domain types; do not infer page-local wire types
- keep client-only islands/components as normal authored client Lustre code

A useful minimal version may be less ambitious than generating whole models: generate default `Msg`, `init`, and `update` for pages that provide only constructor-named handlers. A larger version could generate the entire client page model for pages that declare simple ToClient-to-field storage metadata.

## Why this is still valid but limited

This is not a broad simplification for every current page. In the current app, most client pages do more than plain assignment:

- Games needs `GameUpdated` list replacement and error notice handling.
- Game detail needs selected-game live merge logic.
- Team uses shared page model helpers for live update aggregation.
- Admin Games has real client messages and effects.
- Standings is closest to data-only, but `PowerRankingsLoaded` converts one row type into another.

So the valuable investigation is: can the generator remove the repetitive shell of client page modules without making custom ToClient handling magical?

## Research questions

- Can generated dispatch detect or be told that a page has no local browser messages and provide `NoOp`, `init`, and empty `update` automatically?
- What metadata would be required to generate a whole client model safely for simple data-only pages?
- Should simple data storage be declared in shared page modules, route metadata, or a small page manifest?
- Where is the line between useful generated defaults and magical ToClient handler inference?
- Can this be introduced incrementally, with existing authored modules continuing to work unchanged?
- Which current page, if any, is safe as a first migration target? Standings is the likely candidate, but `PowerRankingsLoaded` conversion may make even that non-trivial.

## Acceptance criteria

- Document the current repeated client page boilerplate and which current pages are data-only versus custom.
- Propose the smallest generator change that reduces boilerplate without hiding runtime boundaries.
- Identify whether this should be a standalone generator feature or part of the generated route boot plan work.
- Include a first migration target or explain why none of the current pages should migrate yet.
- Preserve explicit ToServer/ToClient/domain types and ETF codec simplicity.
- Preserve support for authored client pages with browser-originated messages and client-only effects.
- Name tests to update, especially generated ToClient dispatch tests and any client page tests.
