# Generator Chase Target Plan

This plan turns the next Generator Framework design targets into Scoreboard changes that can be reviewed and implemented one at a time.

The goal is to keep Scoreboard small while forcing the generated modules to handle shapes already present in the larger Curling app.

## Test Coverage Contract

Every chase target must include tests. Generated snapshots and source-shape assertions are useful, but they are not enough for behavior, security, routing, authentication, authorization, or persistence.

Use this rule for every implementation chunk:

- generated-module changes need snapshot or source-shape coverage
- runtime and app behavior need behavior tests
- authentication and authorization rules need positive and negative tests
- SSR boot contracts need encode/decode roundtrip coverage
- navigation and layout rules need rendered HTML assertions or client view tests
- persistence features need database assertions
- live update features need fanout tests with at least two interested clients when relevant
- security-sensitive redirects need safe and unsafe target tests

Do not mark a chase target done when it only has source string checks.

## 1. Add Per-Mount Client Context

### Purpose

Prove that a Mount can boot with shell-level state that every page can read and that page behavior can update.

Curling depends on this shape for admin state such as signed-in identity, role, locale, dark mode, active resource, translations, and root UI state.

Client context is Mount-specific. Authentication is shared app/platform infrastructure. Follow [ADR 0008](adr/0008-use-authentication-context-for-shared-identity.md): public and admin consume `authentication_context`, but neither Mount owns authentication.

For Scoreboard, user-facing authentication routes live in the public Mount. The admin Mount is guarded and only renders after the signed-in user has admin access.

### Scoreboard Target

Add an admin client context with a deliberately small shape:

- authentication context
- admin access flag
- league name
- dark mode flag
- active admin section
- optional toast or flash message

Public can keep a smaller context, such as optional authentication context, league name, and current public section, so the per-Mount difference is visible.

Client contexts should be derived from:

- current route
- shared `authentication_context`
- app-owned authorization facts, such as `is_admin`
- app data needed by the shell, such as league name

Do not derive signed-in state from the current route. A route may require authentication, but the route is not proof that the browser has a session.

### Generated Modules To Exercise

- `server/src/generated/admin/request_context.gleam`
- `server/src/generated/admin/ssr_handler.gleam`
- `server/src/generated/runtime/ssr.gleam`
- `client/src/generated/setup.gleam`
- `client/src/generated/setup_ffi.mjs`
- `client/src/generated/admin/router.gleam`
- `client/src/generated/admin/receiver_dispatch.gleam`
- equivalent public modules if public context is added

### App Code Shape

Add user-owned context modules near the Mount:

```text
shared/src/shared/admin/client_context.gleam
server/src/server/admin/client_context_loader.gleam
client/src/client/admin/client_context.gleam
```

The generated server shell should encode the context into the boot payload. The generated client setup should decode it and pass it into the Mount app init.

Pages should receive the context during init or render. They should not reach into global runtime state.

### Tests

- SSR shell contains encoded admin context.
- Client boot decodes the context.
- Admin nav renders signed-in email and active admin section from context.
- Signed-in display uses `authentication_context.display_label`.
- A page update can emit a toast or context update.
- Public and admin contexts have different types.

### Done Criteria

- Admin page behavior no longer depends on ad hoc shell globals.
- Context is typed per Mount.
- Authentication identity comes from shared `authentication_context`, not admin-owned state.
- Unauthenticated admin requests redirect to the public sign-in route instead of rendering an admin sign-in page.
- Generated snapshots show the boot contract clearly.

## 2. Add Route Kinds By File Suffix

### Purpose

Prove that file-based routing can classify routes that are not normal live pages.

Curling needs normal pages, print HTML, downloads, webhooks, and uploads in the same app.

### Scoreboard Target

Add one tiny route of each kind:

```text
shared/src/shared/admin/pages/games/report.download.gleam
shared/src/shared/admin/pages/games/[id]/scorecard.print.gleam
server/src/server/webhooks/score_feed.webhook.gleam
server/src/server/admin/pages/team_logo.upload.gleam
```

Exact locations can change during implementation if the current Mount layout suggests a better fit. The important bit is that route kind comes from the suffix.

### Generated Modules To Exercise

- `shared/src/generated/admin/route.gleam`
- `client/src/generated/admin/router.gleam`
- `server/src/generated/admin/router.gleam`
- `server/src/generated/entry.gleam`
- `server/src/generated/static_handler.gleam` if route ordering touches static assets
- new generated route metadata helpers if needed

### Route Contracts

Normal `.gleam` routes:

- render through the Mount shell
- can boot the client runtime
- can be intercepted by client navigation

`.print.gleam` routes:

- return standalone HTML
- use the admin print layout
- are not intercepted by client navigation
- can still use print media CSS inside the print layout

`.download.gleam` routes:

- return a file response
- are not intercepted by client navigation
- declare content type and filename in app code

`.webhook.gleam` routes:

- accept external POST input
- bypass normal browser authentication and CSRF rules
- use app-owned secret or signature verification
- return plain HTTP responses

`.upload.gleam` routes:

- accept multipart input
- use upload-specific request limits and parsing
- return a typed status payload or redirect depending on app choice

### Tests

- Generated route parser recognizes each route kind.
- Generated path builder emits the expected URL.
- Client router does not intercept print, download, webhook, or upload targets.
- Print route uses print layout, not the normal admin shell.
- Download route returns file headers.
- Webhook route can update a game through a fake signed request.
- Upload route rejects unsupported file types.

### Done Criteria

- Route kind is generated metadata.
- Route kind behavior is not a pile of one-off checks in `entry.gleam`.
- The docs and generated comments explain where route kind comes from.

## 3. Add Authorization Support Path

### Purpose

Make the generated command path friendly to app-owned permission checks without trying to model every permission rule in generation.

Curling has role-specific, row-level, and function-level checks. That belongs in handlers and domain modules.

This step assumes the shared `authentication_context` vocabulary from [ADR 0008](adr/0008-use-authentication-context-for-shared-identity.md). Authentication answers which user is signed in. Authorization answers whether that user may perform the action.

### Scoreboard Target

Add a tiny `users` table with a boolean admin access flag:

- `admin@example.com`: signed-in user with admin access
- `fan@example.com`: signed-in user without admin access
- anonymous visitor: no authentication context

Admin and public users are both users. The admin user can also use public signed-in features. A public signed-in user can use public signed-in features but cannot access the admin area. Anonymous visitors can view public pages only.

Add a favorite teams feature for signed-in users:

- signed-in users can favorite and unfavorite teams
- favorite teams persist by `user_id`
- anonymous visitors do not see favorite controls
- public users and anonymous visitors do not see the Admin nav link
- signed-in users see Sign Out
- anonymous visitors see Sign In
- admin users see the Admin nav link

The UI can hide admin controls and links for users without admin access, but the server must reject unauthorized admin routes and commands even if the client sends them.

Move Scoreboard sign-in routes into the public Mount shape:

- `/sign_in` renders a public authentication layout variant
- `/sign_out` clears the shared session and redirects to `/games` or `/sign_in`
- `/admin/games` redirects unauthenticated users to `/sign_in?return_to=/admin/games`
- successful sign-in redirects to a safe `return_to` target when present
- admin shell is only used after admin access is granted

Use `user` in runtime and generated naming. Avoid `auth` as a short name.

The user table should be app-owned, but the authentication runtime should normalize and compare email consistently:

```text
id          Int primary identifier
email       normalized unique email
display_name nullable text
is_admin    Bool
```

Email normalization rules:

- trim before storage
- lowercase before storage
- trim before comparison
- lowercase before comparison
- `AuthenticationContext.email` stores the normalized email

Display name rules:

- empty or whitespace-only display names normalize to `None`
- UI uses `authentication_context.display_label`
- when `display_name` is `None`, the display label is the normalized email

Navigation rules:

```text
anonymous public visitor:
  sees Sign In
  does not see Admin
  does not see favorite controls

fan@example.com:
  sees Sign Out
  does not see Admin
  sees favorite controls

admin@example.com:
  sees Sign Out
  sees Admin
  sees favorite controls
```

Template rules:

- public pages use the public shell
- public sign-in uses a public authentication layout variant
- sign-in never renders the admin shell
- sign-in never receives admin client context
- admin pages render only after admin access is granted

Redirect rules:

- `return_to` must be a safe same-origin app path
- sign-in redirects to safe `return_to` when present
- sign-in falls back to `/games` when `return_to` is missing or unsafe
- sign-out clears the shared session
- sign-out from admin redirects to a public route

### Generated Modules To Exercise

- `server/src/generated/admin/request_context.gleam`
- `server/src/generated/admin/dispatch.gleam` or current dispatch equivalent
- `server/src/generated/admin/ws_handler.gleam`
- `server/src/generated/runtime/reject.gleam`
- `server/src/generated/runtime/trace.gleam`

### App Code Shape

Keep policy in server handlers:

```gleam
case authorization.can_update_score(request_context) {
  True -> update_score(...)
  False -> reject.unauthorized(...)
}
```

Generated dispatch should still provide a standard rejection path for:

- unowned Mount commands
- malformed request context
- app-declared unauthorized results when handlers use generated rejection helpers

### Tests

- Email normalization trims and lowercases before storage, lookup, comparison, token creation, and session creation.
- Blank or whitespace-only display names normalize to `None`.
- `authentication_context.display_label` falls back to normalized email when `display_name` is `None`.
- Admin SSR embeds a decodable admin client context.
- Public SSR embeds a decodable public client context.
- Admin user can load `/admin/games`.
- Anonymous visitor hitting `/admin/games` redirects to `/sign_in?return_to=/admin/games`.
- Public signed-in user cannot load `/admin/games`.
- Public signed-in user cannot send admin score commands over the admin socket.
- Rejected admin command does not mutate the database.
- Rejected command emits or logs a useful result.
- Anonymous public visitor can view games, teams, and standings.
- Anonymous public visitor does not see favorite controls.
- Public signed-in user can favorite and unfavorite teams.
- Admin signed-in user can favorite and unfavorite teams.
- Public signed-in user does not see the Admin nav link.
- Anonymous public visitor does not see the Admin nav link.
- Admin signed-in user sees the Admin nav link.
- Sign In and Sign Out links match authentication state.
- Sign-in rejects unsafe `return_to` targets.
- Sign-in accepts safe `return_to` targets.
- Sign-out from admin redirects to a public route.
- Sign-in page does not render the admin shell.
- Favorite team writes persist by `user_id`.
- Anonymous favorite attempts reject and do not write the database.
- Client controls hidden for non-admin users are backed by server tests.

### Done Criteria

- Request context has enough user and admin-access data for handlers.
- Rejection behavior is consistent.
- Authorization policy is still app code.

## 4. Classify Curling Extraction Candidates

### Purpose

Avoid making generation the dumping ground for every repeated pattern.

Curling has enough existing code to sort repeated behavior into better buckets before adding more generated surface area.

### Review Sources

Start with these Curling archive areas:

```text
../../curling/v3/archive/server/src/router.gleam
../../curling/v3/archive/server/src/context.gleam
../../curling/v3/archive/server/src/handler_context.gleam
../../curling/v3/archive/server/src/admin/shell.gleam
../../curling/v3/archive/shared/src/shared/admin/client_context.gleam
../../curling/v3/archive/clients/admin/src/admin/app.gleam
../../curling/v3/archive/clients/admin/src/admin/page.gleam
../../curling/v3/archive/clients/admin/src/admin/upload.gleam
../../curling/v3/archive/server/src/uploads.gleam
../../curling/v3/archive/server/src/uploader.gleam
../../curling/v3/archive/server/src/jobs.gleam
```

### Classification Table

Create a table with these columns:

```text
Pattern
Curling examples
Best home: generator, library, app code, or unclear
Reason
Possible Scoreboard chase target
```

### Initial Biases

Use generator for:

- route derivation from files
- route kind metadata from suffixes
- wire codecs and transport dispatch
- Mount boot contracts
- request context plumbing

Use libraries for:

- validation
- form field state
- UI components
- upload state machines
- job queue runtime
- CSV helpers
- storage adapters

Use app code for:

- business rules
- permissions
- provider-specific webhook behavior
- SQL decisions
- domain-specific page state

For app-owned SQL, prefer file names that describe the operation:

`<verb>_<entity>[_qualifier].sql`

Use the primary entity the handler is asking for, not every table the query
touches. Include the entity for write operations so Marmot function and module
names stay readable as the schema grows. Use qualifiers for audience, route,
or sub-operation.

Examples:

- `create_game.sql`
- `get_game.sql`
- `list_admin_games.sql`
- `list_public_games.sql`
- `update_game_score.sql`
- `update_game_final.sql`
- `get_team_by_slug.sql`
- `list_standings.sql`

Prefer placing the SQL file under the directory for the primary query owner:

- `sql/games/` for game commands and game lists
- `sql/teams/` for team entry points such as `get_team_by_slug.sql`
- `sql/standings/` for standings reads

### Tests

This step is mostly design review. If it creates no code, the output should be a checked-in doc and a short list of recommended follow-up issues.

### Done Criteria

- Each large Curling pattern has a proposed home.
- Any proposed generated feature names the file/type input it is derived from.
- Any proposed library feature has a normal Gleam API sketch.
- The review calls out patterns that should stay app-owned.

## 5. Keep Shared `ToClient` Until It Hurts

### Purpose

Preserve the Lamdera-style root message design while watching for real pressure.

Scoreboard currently benefits from one shared `ToClient` graph: admin score updates can update public pages, team pages, standings, and other admin tabs.

### Current Position

Do not introduce topics or per-Mount `ToClient` graphs yet.

Keep these rules:

- `ToServer` is point-to-point for the current Mount connection.
- `ToClient` is the shared live result and event graph.
- Active receivers are the client-side interest signal.
- Other-Mount `ToServer` commands reject in generated dispatch.
- Cross-Mount `ToClient` delivery is allowed when a receiver handles the constructor.

### Wall To Watch For

Revisit this design when:

- `ToClient` constructors become hard to name without Mount prefixes
- most constructors are meaningful to only one Mount
- receiver dispatch imports too much unrelated domain code
- public and admin need conflicting payload shapes for the same domain event
- fanout needs persisted topics, access-controlled subscriptions, or replay

### Possible Later Direction

If the wall appears, consider:

- app-domain events, such as `GameScoreChanged`
- topic subscriptions behind generated Mount receivers
- server-side translation from domain events to Mount-specific `ToClient`
- BEAM process groups or pubsub actors for local fanout
- database-backed notifications only if persistence or replay is needed

### Tests

Keep the existing fanout tests strong:

- admin score update reaches another admin tab
- admin score update reaches public game pages
- admin score update reaches public team pages for involved teams
- finalized game updates standings and team records

### Done Criteria

- No new fanout abstraction is added yet.
- The docs name the warning signs that would justify a redesign.
- Current fanout tests keep proving the shared graph works.
