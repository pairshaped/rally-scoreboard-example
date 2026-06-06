# Colocate Authored SQL

Authored SQL files live beside the page or workflow that owns the server behavior, in a local `sql/` directory.

Examples:

```text
src/public/pages/items.gleam
src/public/pages/items/sql/list_items.sql

src/public/pages/items/id_.gleam
src/public/pages/items/id_/sql/get_item.sql
```

Generated Marmot output still belongs under `src/generated/sql`.

This keeps authored query ownership close to the page or workflow that shapes the result, while generated typed SQL remains centralized and importable from Erlang-only server code.
