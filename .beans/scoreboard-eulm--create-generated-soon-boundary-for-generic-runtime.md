---
# scoreboard-eulm
title: Create generated_soon boundary for generic runtime glue
status: todo
type: task
priority: high
tags:
    - architecture
    - generated-soon
created_at: 2026-06-02T10:03:43Z
updated_at: 2026-06-02T10:03:43Z
parent: scoreboard-d0g1
---

## Problem

The unified app has generic code living in app-shaped modules such as src/client/*, browser helpers, hydration helpers, and pieces of scoreboard_unified.gleam. This makes the app look split even though the package is unified.

## Direction

Create src/generated_soon/ as a quarantine for code that is generic enough to be generated later, but whose final generator or library boundary is not settled yet. Move only code that is clearly generic or generated-shaped. Keep app-specific page, API, auth policy, SQL, and shell content outside this directory.

Candidate areas:

- Browser boot attrs, navigation event plumbing, and history helpers.
- Websocket transport and generated frame plumbing.
- ETF hydration reader/writer shape.
- Generic mount startup helpers if they can be moved without obscuring public/admin concrete types.

## Acceptance criteria

- src/generated_soon/ exists and contains only code that is plausibly generated later.
- App-specific names are reduced or isolated as parameters/config.
- Existing generated/ code remains untouched unless an import path needs to change.
- Both JS and Erlang builds pass.
- Browser smoke still passes for SSR hydration, SPA navigation, and websocket updates.
