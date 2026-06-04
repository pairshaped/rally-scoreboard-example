---
# scoreboard-unified-u7w3
title: Resolve the Libero and Rally runtime dependency strategy
status: completed
type: task
priority: high
tags:
    - rally
    - chase
    - hitl
created_at: 2026-06-04T03:38:31Z
updated_at: 2026-06-04T17:10:12Z
parent: scoreboard-unified-wm8p
---

## What to decide

Decide whether Libero and Rally runtime modules remain runtime dependencies, or whether Rally/Libero generate the small runtime bits needed by the app.

This is intentionally draft/HITL. The decision affects the dependency story, generated code volume, debug ergonomics, and whether Rally feels like a compiler/generator or an application runtime.

## Plan outline

- Inventory current runtime imports from Rally and Libero in the chase app.
- Separate essential browser/API shims from generator-only helpers.
- Compare two approaches:
  - keep small runtime packages as dependencies;
  - generate runtime shims into the app.
- Evaluate whether generated runtime deps would reduce target soup or hide too much behavior.
- Decide the public API shape for `server.send(..., on_result: ...)` once page-local generation owns result types.
- Record the decision in an ADR and update the chase plan.

## Acceptance criteria

- [ ] Current Rally and Libero runtime usage is inventoried.
- [ ] A recommended dependency strategy is documented with tradeoffs.
- [ ] The decision says what is generated, what remains runtime, and why.
- [ ] The `server.send(..., on_result: ...)` target API direction is captured.
- [ ] Follow-up implementation beans are created if the decision requires code changes.

## Blocked by

Needs human design review before implementation.


Decision recorded in ADR 0011: keep Libero and Rally runtime dependencies, with Libero owning ETF codec/runtime output and Rally composing neutral Libero helpers from generated/rally glue.

Current runtime inventory captured in ADR 0011:

• generated/libero/result for page-local API boundary errors
• generated/libero/codec_ffi.mjs for browser ETF encode/decode
• Libero Erlang codec helpers for safe server decode and ETF encode
• generated/rally/client_transport for websocket connection, request ids, and callback dispatch
• generated/rally/client_protocol and generated/rally/server_protocol for envelopes
• generated/rally browser, boot, hydration, and mount helpers for browser framework plumbing

Follow-up implementation beans:

• scoreboard-unified-58jn: Expose neutral Libero ETF codec helper
• scoreboard-unified-cu1k: Consume neutral Libero codec helper in Rally glue
