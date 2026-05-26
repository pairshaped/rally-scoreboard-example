# Architecture Decision Records

These ADRs describe the Generator Framework contract that Scoreboard validates.

Scoreboard is the golden example app for a potential code generator framework. It exercises the generated root API, generated runtime, Mount layout, wire protocol, authentication, live updates, logging, and database boundaries that the Generator Framework should support.

This repo does not implement the Generator Framework and does not run app generation itself. Generated app code is checked in as the hand-written target for future generator work. Marmot is the exception: it generates typed SQL modules from the SQL files in `server/src/server/sql/`.

The ADRs describe the intended design, not a history of how the current files moved here.

Lowercase `rally` remains in literal paths, module namespaces, and config names where the current generated code still uses that namespace.
