# Use Authentication Context For Shared Identity

Scoreboard uses one shared authentication context type for signed-in browser
identity. Public and admin code consume that context and apply their own access
or authorization rules.

Authentication is app-owned runtime behavior. Generated route modules may carry
route metadata and page wiring, but they do not own sessions, provider handoff,
or authorization policy.

## Decision

The app-owned shared identity type is `authentication_context.AuthenticationContext`:

```gleam
pub type AuthenticationContext {
  AuthenticationContext(
    user_id: Int,
    email: String,
    display_name: Option(String),
  )
}
```

Use `user` for the signed-in identity row. Use `account` only when app code is
specifically talking about a billing, provider, or tenant account.

Use these terms consistently:

- `user`: the signed-in identity row
- `authentication`: proving who the browser session represents
- `authentication_context`: app-owned identity facts loaded from a session
- `authorization`: deciding what the user may do
- `ClientSharedState`: Mount-specific browser state derived from route,
  authentication context, authorization facts, and app data
- `ToServer`: browser-to-server command vocabulary
- `ToClient`: server-to-browser app data vocabulary
- `access guard`: route or Mount check that decides whether a request may load

Avoid `auth` in generated names because it can mean authentication or
authorization.

`email` is globally unique. The app stores and compares email addresses after
trimming whitespace and lowercasing.

`display_name` is optional. Empty or whitespace-only display names normalize to
`None`. UI code renders a display label through
`authentication_context.display_label`.

## Scoreboard User Model

Scoreboard exercises authentication and authorization with a small app-owned
`users` table:

```text
id          Int primary identifier
email       normalized unique email
display_name nullable text
role        text role: admin or fan, default fan
```

The `role` field is Scoreboard app policy. It is not a generated authorization
model.

Admin access derives from the app-owned `users.role` value. Anonymous visitors
have no authentication context.

## Mount Integration

Mounts consume authentication context. They do not own authentication.

Public pages may receive:

```gleam
authentication_context: Option(AuthenticationContext)
```

Admin pages are guarded by app-owned routing or request handling before the
admin app renders. Admin pages may still carry an optional authentication
context in shared state so navigation and labels have one shape.

Handlers own authorization policy. They decide whether the authenticated user
may perform a command, update a row, or view a resource.

For the current websocket path, server commands are dispatched by app code in
`app_api.gleam`. Any user/session facts needed by those commands should be
added to app-owned request or connection state before handler dispatch.

## Navigation

Authentication state affects Mount templates and navigation.

Public pages:

- anonymous visitors see Sign In
- signed-in users see Sign Out
- admin users also see Admin
- non-admin users do not see Admin
- anonymous visitors do not see Admin

Admin pages:

- render only after the signed-in user has admin access
- show the admin layout and admin navigation
- can show the signed-in user's display label

Sign-in and sign-out routes live in the public Mount for Scoreboard:

```text
/sign_in
/sign_out
```

Admin routes are guarded:

```text
/admin/games
```

An unauthenticated request to an admin route redirects to a sign-in route with a
validated same-origin `return_to` path. Signing out clears the shared session
and redirects to a public route.

## External Provider Handoff

External provider callbacks are separate from the placement of user-facing
authentication routes.

If OAuth or SSO is added, provider callbacks should use a stable callback host
or route so the app does not need to register every league subdomain with the
provider.

The callback route verifies provider state and creates a short-lived handoff
token. The destination host redeems that token server-side, sets its own session
cookie, and redirects to the validated return path.

These routes are app-owned. Generated route metadata may help build URLs, but
the session, token, and provider behavior belongs in runtime or library code.
