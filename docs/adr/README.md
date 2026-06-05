# Architecture Decision Records

These ADRs describe the generated-source contract that Scoreboard validates.

Scoreboard exercises page-local Rally contracts, target-scoped source, Proute routing, generated framework glue, page-owned domain data, API/RPC effects, wire boundary validation, colocated authored SQL, and stable source style.

This repo checks in generated source under `src/generated` while the unified source shape is being proven. Marmot and Proute already write generated modules there.

The ADRs describe the intended design.

## Records

- [0001: Use Page Local Rally Contracts](0001-use-page-local-rally-contracts.md)
- [0002: Keep Page Domain Models Local](0002-keep-page-domain-models-local.md)
- [0003: Use Proute For Routing And Page Glue](0003-use-proute-for-routing-and-page-glue.md)
- [0004: Generate Target Specific Framework Glue](0004-generate-target-specific-framework-glue.md)
- [0005: Enforce Wire Boundaries](0005-enforce-wire-boundaries.md)
- [0006: Colocate Authored SQL](0006-colocate-authored-sql.md)
- [0007: Preserve Authoring Style](0007-preserve-authoring-style.md)
- [0008: Use API RPC Effects](0008-use-api-rpc-effects.md)
- [0009: Separate Libero Proute And Rally Roles](0009-separate-libero-proute-and-rally-roles.md)
- [0010: Separate Mutation Results From Broadcast Events](0010-separate-mutation-results-from-broadcast-events.md)
- [0011: Keep Codec Runtime Dependencies](0011-keep-codec-runtime-dependencies.md)
- [0012: Use Convention Driven Rally App Surface](0012-use-convention-driven-rally-app-surface.md)
