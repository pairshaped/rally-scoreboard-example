# Scoreboard

Scoreboard is Rally's golden path example.

It is a small sports app with a public scoreboard and an admin score desk. The point is to exercise Rally's root API app shape with a domain small enough to keep the generator work honest.

## Shape

- `shared/` owns wire-visible API types under `shared/api`.
- `server/` owns handlers, fake data, request context, server context, and backend modules.
- `client/` owns receiver mapping and browser-side app entry modules.

The workspace root is the Scoreboard tooling package. App code lives in `client/`, `server/`, and `shared/`. The sibling `../rally/` package is used as the local Rally dependency.

The server package is SQLite-backed. Handwritten SQL lives under `server/src/server/sql/`, migrations live under `server/db/migrations/`, and Marmot writes typed query modules under `server/src/generated/sql/`.

The public and admin shells load Oat from the CDN. Page views can lean on semantic HTML first, with Oat styling native elements directly instead of adding a Gleam UI dependency.

From `server/`:

- `gleam run -m marmot migrate`
- `gleam run -m marmot`
- `gleam run`

## Public

- `/games`
- `/games?team=TOR`
- `/games/:id`
- `/standings`

Public pages can load games, filter by team query param, load one game, and receive live score or standings updates.

## Admin

- `/admin/games`
- `/admin/games/new`
- `/admin/games/:id`

Admin pages can create games, update scores, mark final results, and correct results.

## Generation Targets

The app intentionally uses one shared API graph for public and admin messages. Wire-visible constructor names must be globally unique across that graph, regardless of module path.

Generated code is checked in here as the hand-written target for Rally. Server tests snapshot every generated module so future generator work has a tight comparison loop.
