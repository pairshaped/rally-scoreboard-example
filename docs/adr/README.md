# Architecture Decision Records

These ADRs describe the generated-source contract that Scoreboard validates.

Scoreboard exercises page-local Rally contracts, target-scoped source, Proute routing, generated framework glue, and page-owned domain data.

This repo checks in generated source under `src/generated` while the unified source shape is being proven. Marmot and Proute already write generated modules there.

The ADRs describe the intended design.

## Records

- [0001: Use Page Local Rally Contracts](0001-use-page-local-rally-contracts.md)
- [0002: Keep Page Domain Models Local](0002-keep-page-domain-models-local.md)
- [0003: Use Proute For Routing And Page Glue](0003-use-proute-for-routing-and-page-glue.md)
- [0004: Generate Target Specific Framework Glue](0004-generate-target-specific-framework-glue.md)
