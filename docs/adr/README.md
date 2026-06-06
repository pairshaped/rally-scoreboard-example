# Architecture Decision Records

These ADRs describe application decisions in the Rally Scoreboard example.

Rally framework decisions live in the Rally repository ADRs. Scoreboard should
not duplicate those records.

Scoreboard exercises Rally's page-local contract, generated Proute/Rally/Libero
glue, typed broadcasts, SSR, hydration, and browser navigation. Its local ADRs
cover choices that belong to this example app.

This repo checks in generated source under `src/generated` so the example can be
read without running every generator first.

## Records

- [0001: Keep Page Domain Models Local](0001-keep-page-domain-models-local.md)
- [0002: Colocate Authored SQL](0002-colocate-authored-sql.md)
