---
# scoreboard-l651
title: Add encrypted auth session and device cookie bag
status: completed
type: task
priority: normal
tags:
    - authentication
    - cookies
    - javascript-target
    - erlang-target
created_at: 2026-06-01T22:14:38Z
updated_at: 2026-06-01T23:32:11Z
---

## Problem

The unified app has the device dark-mode preference tracer bullet, but it does not yet have the full authentication model from scoreboard-sc.

Admin routes are currently visible without an encrypted server-owned session. The public shell also has placeholder shared-state fields for authentication and admin access, but those fields are not backed by real request/session data.

## Direction

Model the implementation after ../scoreboard-sc, with the same separation of responsibilities:

- _scoreboard_session is server-owned, encrypted, authenticated, HttpOnly, SameSite=Lax, and scoped to /
- _scoreboard_device remains browser-owned and non-sensitive
- shared query-style payload parsing stays in reusable Gleam code
- server target reads and verifies the session before serving admin routes
- browser target may update device preferences, but must not read or write the session cookie
- ClientSharedState carries authenticated shell facts such as authentication_context and can_access_admin

Keep the device preference work as the simple cookie bag. Do not mix sensitive session state into that client-writable payload.

## Source references

- ../scoreboard-sc/server/src/server/session.gleam
- ../scoreboard-sc/server/src/server/auth.gleam
- ../scoreboard-sc/server/src/scoreboard_server.gleam
- ../scoreboard-sc/docs/adr/0016-use-encrypted-session-and-device-preference-cookies.md
- src/device_preferences.gleam
- src/public/client_shared_state.gleam
- src/admin/client_shared_state.gleam

## Acceptance criteria

- Public sign-in can set a valid encrypted admin session cookie.
- Invalid or missing sessions cannot access /admin or /admin/games.
- Signing out expires the session cookie.
- The session cookie is HttpOnly, SameSite=Lax, Path=/, and not readable from JavaScript.
- The device cookie remains client-writable and continues to preserve dark-mode preference.
- ClientSharedState reflects real authentication/admin access state.
- Both JavaScript and Erlang target builds pass.


## Completed notes

Implemented the unified app auth tracer bullet against the `../scoreboard-sc` reference shape:

- `_scoreboard_session` is server-owned, encrypted/authenticated with AES-256-GCM, `HttpOnly`, `SameSite=Lax`, and scoped to `/`.
- Sign-in uses a normal HTTP POST to `/sign_in`, validates the seeded demo admin code, sets the session cookie, and redirects to the safe admin return path.
- Sign-out expires the session cookie and redirects to a safe local path.
- `/admin` and `/admin/games` redirect anonymous or invalid sessions to `/sign_in?return_to=...`.
- WebSocket admin commands require an admin session from the connection request; unauthenticated admin commands receive `AdminError("Unauthorized.")`.
- The public/admin shell boot state receives non-sensitive authentication facts from server-rendered `#app` data attributes. JavaScript does not read or write `_scoreboard_session`.
- `_scoreboard_device` remains browser-owned and continues to drive dark-mode preference.

Validation run before completion:

- `gleam format src test`
- `gleam check`
- `gleam build --target javascript`
- `gleam build --target erlang`
- `gleam test`
- `gleam run -m glinter`
- `beans check`
- `git diff --check`
- HTTP smoke: admin redirect, sign-in cookie issuance, authenticated admin document boot attrs, invalid-code redirect, sign-out expiry
- Playwright smoke: unauthenticated admin redirect, client-rendered sign-in form, admin sign-in, `document.cookie` cannot see `_scoreboard_session`, sign-out, admin route guarded again


Session key configuration now reads `SCOREBOARD_SECRET_KEY_BASE` when present. The value must decode to exactly 32 bytes. Missing env falls back to an in-memory development key so local smoke runs still work; invalid env stops startup through the main startup assertion after logging the config error.
