# Colocate Authored SQL

## Status

Accepted

## Decision

Authored SQL files live beside the page or workflow that owns the server
behavior, in a local `sql/` directory.

Examples:

```text
src/public/pages/games.gleam
src/public/pages/games/sql/list_games.sql

src/public/pages/games/id_.gleam
src/public/pages/games/id_/sql/get_game.sql

src/admin/pages/games.gleam
src/admin/pages/games/sql/update_game_score.sql
```

Generated Marmot output stays under `src/generated/sql`.

## Consequences

Authored query ownership stays close to the page or workflow that shapes the
result.

Generated typed SQL stays centralized and importable from Erlang-only server
code.
