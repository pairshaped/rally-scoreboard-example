# Architecture Decision Records

These ADRs describe the Generator Framework contract that Scoreboard validates.

Scoreboard is the golden example app for the Generator Framework. It exercises the generated root API, generated runtime, Mount layout, wire protocol, authentication, live updates, logging, and database boundaries that the Generator Framework supports.

This repo does not implement the Generator Framework and does not run app generation itself. Generated app code is checked in as the hand-written target shape for generator output. Marmot is the exception: it generates typed SQL modules from the SQL files in `server/src/server/sql/`.

The ADRs describe the intended design.

Literal config names use lowercase `rally`.

## Records

- [0002: Keep Dispatch Effect Agnostic](0002-keep-dispatch-effect-agnostic.md)
- [0003: Use ToClient For Server Operation Outcomes](0003-use-to-client-for-server-operation-outcomes.md)
- [0004: Use ToClient For Live Updates](0004-use-to-client-for-live-updates.md)
- [0005: Use Server Runtime State For Live Connections](0005-use-server-runtime-state-for-live-connections.md)
- [0006: Default To Root API Contracts](0006-default-to-root-api-contracts.md)
- [0007: Use File Routes, Route Kinds, And Mount Contexts](0007-use-file-routes-route-kinds-and-mount-contexts.md)
- [0008: Use Authentication Context For Shared Identity](0008-use-authentication-context-for-shared-identity.md)
