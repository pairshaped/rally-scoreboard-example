# Use Authentication Context For Shared Identity

The Generator Framework uses `authentication_context` for the signed-in browser identity shared by Mounts.

Public, admin, system, and authentication callback routes do not own authentication. They consume a shared authentication context and apply their own access or authorization rules.

## Decision Summary

Authentication is framework infrastructure with app-placed routes.

The framework provides the shared identity contract, normalization helpers, session helpers, access guard plumbing, redirect helpers, and provider handoff helpers. The app decides where user-facing sign-in and sign-out routes live.

The framework does not require a fixed authentication Mount. An app can put sign-in routes in the public Mount, in a dedicated authentication Mount, or in multiple entry points. The generated code must carry enough route metadata to support that placement.

Scoreboard uses public-owned authentication routes because it is a small app:

```text
/sign_in
/sign_out
```

Scoreboard admin pages are guarded routes:

```text
/admin/games
```

The admin Mount only renders after the signed-in user has admin access.

## Taxonomy

Use `user` for the framework-facing identity.

Use `account` only when app code is specifically talking about a billing, provider, or tenant account.

Use these terms consistently:

- `user`: the signed-in identity row
- `authentication`: proving who the browser session represents
- `authentication_context`: the framework-facing identity loaded from a session
- `authorization`: deciding what the user may do
- `client_context`: Mount-specific shell state derived from route, authentication context, and app data
- `request_context`: per-request or per-socket server context passed to handlers
- `access guard`: route or Mount check that decides whether a request may load

Avoid `auth` in generated names because it can mean authentication or authorization.

## Authentication Context Shape

The shared runtime authentication context has a small app-facing contract:

```gleam
pub type AuthenticationContext {
  AuthenticationContext(
    user_id: Int,
    email: String,
    display_name: Option(String),
  )
}
```

`user_id` is an `Int`.

`email` is globally unique. The runtime always stores and compares email addresses after trimming whitespace and lowercasing.

`display_name` is optional. Empty or whitespace-only display names normalize to `None`.

UI code renders a display label through the runtime helper:

```gleam
pub fn display_label(context: AuthenticationContext) -> String {
  case context.display_name {
    Some(name) -> name
    None -> context.email
  }
}
```

If `display_name` is `None`, the display label is the normalized email.

## Runtime Helpers

Authentication behavior belongs in framework runtime or library code before it belongs in generated code.

The runtime provides helpers like:

```gleam
pub fn normalize_email(email: String) -> String
pub fn normalize_display_name(name: String) -> Option(String)
pub fn display_label(context: AuthenticationContext) -> String
```

Any built-in sign-in link, sign-in code, password, OAuth, or handoff helper must normalize email before lookup, storage, comparison, token creation, password verification, or session creation.

When the framework provides a reference users table, its email column stores only normalized emails and has a unique index.

## Scoreboard User Model

Scoreboard exercises authentication and authorization with a tiny app-owned `users` table.

The table includes:

```text
id          Int primary identifier
email       normalized unique email
display_name nullable text
role        text role: admin or fan, default fan
```

Seed users:

```text
admin@example.com   role = admin
fan@example.com     role = fan
```

Both rows are users. The admin user can use public signed-in features. The fan user can use public signed-in features but cannot access admin routes or admin commands. Anonymous visitors have no authentication context.

The `role` field is Scoreboard app policy. It is not the framework authorization model. Scoreboard exposes authorization facts such as `can_access_admin` from that role.

## Mount Integration

Mounts consume authentication context. They do not own authentication.

Public Mounts may allow anonymous requests and receive:

```gleam
authentication_context: Option(AuthenticationContext)
```

Admin or system Mounts may require a signed-in user through an access guard. Request context can still carry the optional authentication context so the generated shape stays simple:

```gleam
RequestContext(
  authentication_context: Option(AuthenticationContext),
  ...
)
```

Handlers own authorization policy. They decide whether the authenticated user may perform a command, update a row, or view a resource.

Generated code helps by passing authentication context consistently and by giving guarded Mounts a standard redirect or rejection path.

For Scoreboard, admin access derives from the app-owned `users.role` value. That is an example app policy, not a framework-wide authorization model.

## Navigation And Layout

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
- can also show the signed-in user's display label

Sign-in page:

- lives in the public Mount for Scoreboard
- uses a public authentication layout variant
- does not render the normal admin shell
- does not render admin score-desk navigation
- does not receive admin client context

This keeps authentication UI from pretending to be an unauthenticated admin page. It also prevents the bug where admin identity or permissions are embedded in a sign-in page before the user is signed in.

## Authentication Routes

The framework does not require a fixed authentication Mount.

Authentication is shared infrastructure. The app decides where user-facing authentication routes live. A small app may put sign-in and sign-out routes in its public Mount. A larger app may use a dedicated authentication Mount or multiple sign-in entry points.

Generated code supports that placement by carrying route metadata, access guards, redirect targets, and authentication context through the selected Mount.

For Scoreboard, authentication routes live in the public Mount:

```text
/sign_in
/sign_out
```

Admin routes are guarded:

```text
/admin/games
```

An unauthenticated request to `/admin/games` redirects to `/sign_in?return_to=/admin/games`. After sign-in, the app redirects to the safe `return_to` target. Signing out from admin clears the shared session and redirects to a public route such as `/games` or `/sign_in`.

The sign-in page uses a public authentication layout variant. It does not render the admin Mount shell or admin score-desk navigation. This prevents unauthenticated admin pages from receiving admin client context.

`return_to` must be validated before redirecting. It is a same-origin path owned by the app.

Sign-out clears the shared session, not an admin-only session. Signing out from an admin route redirects to a public route so the browser does not land on a guarded admin page without a session.

## External Provider Handoff

External provider callbacks are a separate concern from the placement of user-facing authentication routes.

OAuth provider redirects use a stable callback host or route so the app does not need to register every league subdomain with the provider.

The callback route verifies provider state and creates a short-lived handoff token. It does not create the final league-subdomain browser session.

The intended flow is:

```text
club.example.com/admin/sign_in
  -> provider login
  -> auth.example.com/google/callback
  -> club.example.com/auth/complete?handoff=...
  -> club.example.com/admin/games
```

The destination host redeems the handoff token server-side, sets its own session cookie, and redirects to the original return path.

This means the framework needs absolute URL helpers and host-aware request context for callback and handoff routes. It does not mean public or admin Mounts own authentication.

The callback host cannot set the final host-only session cookie for a different league subdomain. That is why the handoff completion route must run on the destination host.

The framework pieces are:

- provider callback route verifies provider state
- callback route creates a short-lived handoff token
- callback route redirects to the destination host
- destination host redeems the token
- destination host sets its own session cookie
- destination host redirects to the safe return path

These routes may live in the same Mount or different Mounts. The framework supports both placements.
