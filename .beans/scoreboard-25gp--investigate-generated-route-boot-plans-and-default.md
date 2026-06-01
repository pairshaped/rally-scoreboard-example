---
# scoreboard-25gp
title: Investigate generated route boot plans and default client init
status: todo
type: task
priority: normal
tags:
    - ergonomics
    - generation
    - hydration
created_at: 2026-05-30T20:35:53Z
updated_at: 2026-05-30T20:35:53Z
---

## Problem

The sibling app has a promising ergonomics improvement around route/page boot, but the current implementation still spreads init knowledge across shared page modules, client shells, generated SSR handlers, and transport behavior.

Today, shared pages expose `init_requests() -> List(ToServer)`, generated SSR calls those functions and pattern-matches expected commands, and authored client shells manually map routes to `init_requests()`, page-init module names, params, query, and load effects.

That creates several problems:

- route boot knowledge is duplicated across SSR and client shell code
- generated SSR has `init_requests mismatch` branches that should not be needed if the generator owns the mapping
- client shell code has to know which shared page init function and page-init module string belongs to each route
- current client navigation only uses the first init request in several branches, even though multi-command page init is a valid use case
- client page modules currently need `init()` even when they only store server-loaded data and have no client-local behavior

## Direction to investigate

Investigate a generated route boot plan that keeps the sibling app architecture, but removes the manual boot wiring.

The goal is not to generate arbitrary page logic or collapse `client/`, `server/`, and `shared/` into one runtime. Keep explicit ToServer/ToClient contracts, true hydration, compact ETF payloads, and client-only SPA escape hatches.

Candidate shape:

- keep shared page `init_requests()` or rename it to `init_commands()` if the concept is specifically server commands
- support multiple init commands, not just the first command
- generate route-to-page-init metadata: module name, params, query shape, and commands
- generate client shell helpers for initial load and SPA navigation from the same boot metadata
- generate SSR boot execution from the same metadata instead of hand-written command checks per route
- optionally generate a default client page model/handler for pages that omit client `init()` and only need server-loaded data
- require an explicit client page module only when a page has client-local state/effects such as drag/drop, pointer interactions, local filters, optimistic UI, or browser APIs
- preserve a separate client-only init hook for browser-native setup that is not a server load command

## Important constraints

- Do not make this a transpiler. Avoid splitting one arbitrary source module into server/client/shared outputs.
- Do not infer page-local wire types. Stable shared ToServer/ToClient/domain types remain important for simple ETF encoding and decoding.
- Do not hide runtime boundaries. Client-only behavior should stay visibly client-only.
- Do not remove the ability for page init to kick off multiple server commands.
- Do not force every init operation to be a server resource load. Some init work may be client-only.

## Current code references

- `shared/src/shared/public/pages/games.gleam` exposes `init_requests()` returning `[to_server.LoadGames]`.
- `shared/src/shared/public/pages/standings.gleam` exposes `init_requests()` returning `[to_server.LoadStandings]`.
- `shared/src/shared/admin/pages/games.gleam` exposes `init_requests()` returning `[to_server.LoadAdminGames]`.
- `client/src/scoreboard_public_client.gleam` manually maps routes to init requests in `initial_load` and `load_route`, and manually maps route to page-init module strings in `route_page_init`.
- `client/src/scoreboard_admin_client.gleam` manually maps admin route boot and page init.
- `server/src/generated/public/ssr_handler.gleam` calls shared `init_requests()` and pattern-matches expected commands, including `init_requests mismatch` fallbacks.
- `server/src/generated/admin/ssr_handler.gleam` does the same for admin.
- `client/src/generated/public/to_client.gleam` currently assumes each client page module has `init()`.
- `client/src/generated/admin/to_client.gleam` currently assumes each admin client page module has `init()`.

## Research questions

- Should `init_requests()` remain authored in shared page modules, or should route boot metadata be declared somewhere else?
- Can generated client shell code fully replace the handwritten route-to-init-command logic while still allowing client-only init hooks?
- What is the right representation for multiple boot commands over the socket?
- Should page init and command batches be combined with the existing duplicate-frame optimization, or kept as a separate design?
- Can the generator provide a useful default client model for simple data-only pages without making ToClient handlers magical?
- How should default client page generation handle pages with multiple ToClient constructors or live-update handlers?

## Acceptance criteria

- Produce a concrete design proposal for generated route boot metadata and client/SSR execution.
- Identify the smallest implementation slice that improves ergonomics without becoming a transpiler.
- Include migration notes for current Games, Standings, Team, Game detail, and Admin Games pages.
- Preserve support for multiple init commands.
- Preserve support for client-only components and client-only init code.
- Name tests that should cover the change, especially SSR hydration, SPA navigation, admin auth, and multi-command init.
