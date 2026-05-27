# Scoreboard

Scoreboard is the golden example app for a potential code generator framework.

It is a small sports app with a public scoreboard and an admin score desk. The point is to exercise every feature we want the Generator Framework to support, using a domain small enough to keep the generator work honest.

This project does not implement the Generator Framework and does not run app generation itself. The generated app code checked in here is the hand-written target the future generator should match. Marmot is the exception: it generates typed SQL modules from the SQL files in `server/src/server/sql/`.

## Shape

- `shared/` owns wire-visible API types under `shared/api`.
- `server/` owns handlers, fake data, request context, server context, and backend modules.
- `client/` owns receiver mapping and browser-side app entry modules.

The workspace root is the Scoreboard tooling package. App code lives in `client/`, `server/`, and `shared/`. The sibling `../rally/` package provides the tooling configuration for Mount namespaces.

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

- `/admin/sign_in/password`
- `/admin/sign_in/code`
- `/admin/games`

Admin pages require authentication. Admin users can create games, update scores, mark final results, and correct results from the games page.

## Generation Targets

The app intentionally uses one shared API graph for public and admin messages. Wire-visible constructor names must be globally unique across that graph, regardless of module path.

Generated code is checked in here as the hand-written target for the Generator Framework. Server tests snapshot every generated module so future generator work has a tight comparison loop.
