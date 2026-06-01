# Architecture Decision Records

These ADRs describe the generated-source contract that Scoreboard validates.

Scoreboard exercises the generated root API, generated runtime, Mount layout, wire protocol, authentication, live updates, logging, and database boundaries.

This repo checks in generated source under `src/generated` while the unified source shape is being proven. Marmot and Proute already write generated modules there.

The ADRs describe the intended design.

## Records

- [0002: Keep Dispatch Effect Agnostic](0002-keep-dispatch-effect-agnostic.md)
- [0003: Use ToClient For Server Operation Outcomes](0003-use-to-client-for-server-operation-outcomes.md)
- [0004: Use ToClient For Live Updates](0004-use-to-client-for-live-updates.md)
- [0005: Use Server Runtime State For Live Connections](0005-use-server-runtime-state-for-live-connections.md)
- [0006: Default To Root API Contracts](0006-default-to-root-api-contracts.md)
- [0007: Use File Routes, Route Kinds, And Mount Contexts](0007-use-file-routes-route-kinds-and-mount-contexts.md)
- [0008: Use Authentication Context For Shared Identity](0008-use-authentication-context-for-shared-identity.md)
- [0009: Use Target Annotations For Unified Source](0009-use-target-annotations-for-unified-source.md)
