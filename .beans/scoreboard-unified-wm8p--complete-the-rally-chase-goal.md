---
# scoreboard-unified-wm8p
title: Complete the Rally chase goal
status: todo
type: epic
priority: high
tags:
    - rally
    - chase
created_at: 2026-06-04T03:36:11Z
updated_at: 2026-06-04T03:36:11Z
---

## What to build

Use `scoreboard-unified` as the chase app for Rally's next direction: page-local server handlers, target-annotated centralized `src/` authoring, thin generated wire glue, colocated SQL, and humane boundary diagnostics.

This epic is done when the chase app no longer depends on hand-edited generated glue or global root API/domain contracts for ordinary page load and save flows.

## Plan outline

- Replace global root API messages with page-local wire contracts one vertical route/workflow at a time.
- Teach Rally/Libero generation to produce the current hand-written chase glue.
- Prove loads use correlated RPC result payloads and saves use correlated results plus self-broadcast where appropriate.
- Keep authored SQL beside owning pages/workflows and generated SQL under generated output.
- Add diagnostics and stop-condition checks so the chase evaluates the real Rally direction instead of drifting into framework rewrite fog.

## Acceptance criteria

- [ ] Page/workflow-owned domain models and server handlers are local to their owners.
- [ ] Generated code is thin glue, codecs, route glue, or build metadata only.
- [ ] Client app generation is gone from the chase path.
- [ ] Boundary failures name the contract, offending type/import, and path to the violation.
- [ ] The chase app builds and smoke tests pass without hand-edit-only generated behavior.

## Blocked by

None - can start immediately.
