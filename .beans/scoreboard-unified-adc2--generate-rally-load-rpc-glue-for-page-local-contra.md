---
# scoreboard-unified-adc2
title: Generate Rally load RPC glue for page-local contracts
status: completed
type: feature
priority: high
tags:
    - rally
    - chase
created_at: 2026-06-04T03:38:31Z
updated_at: 2026-06-04T16:48:25Z
parent: scoreboard-unified-wm8p
blocked_by:
    - scoreboard-unified-v4f9
---

## What to build

Teach Rally to generate the load RPC glue proven by the public games tracer bullet. Rally should generate the request envelope, result decoding, page boot integration, and page-message callback wiring without requiring hand-edits in generated modules.

Generated output should stay thin: route glue, codecs, dispatch, and build metadata. It should not generate a full client app from server-shaped source.

## Plan outline

- Use the public games tracer bullet as the concrete target behavior.
- Generate route-scoped load request metadata from page-local server handlers.
- Generate correlated result decoding that dispatches into the page's own `Loaded(...)` message.
- Keep Proute responsible for URL route identity; Rally consumes that identity for wire dispatch.
- Preserve `gleam format` output and avoid import churn beyond what the formatter owns.
- Add a generation smoke test that fails if hand-edited generated glue is required.

## Acceptance criteria

- [ ] Rally generation produces the load RPC glue needed by the public games page.
- [ ] Regenerating does not overwrite the chase behavior back to root API dispatch.
- [ ] Generated code remains route glue, codecs, dispatch, and metadata only.
- [ ] `gleam format`, `gleam test`, and browser smoke tests pass after regeneration.
- [ ] The generated output follows the documented section/comment style where applicable.

## Blocked by

- Public games page-local load tracer bullet.



Completed in Rally commit d8115f9 and chase commit 20b2841. Rally load-rpc now discovers both public page-local wire modules and page-owned admin contracts, keeps page-owned contracts out of generated browser imports to avoid cycles, emits typed server helpers, emits generic client result helpers for page-owned payloads, and preserves broadcasts.Event for push frames. Regenerating chase with `gleam run -m rally load-rpc` no longer overwrites the page-local behavior back to root API dispatch.

Validated with:

• Rally `gleam build`
• Rally `gleam test --target erlang` (snapshot-clean; existing JSON fixture failures remain because fixtures/json_protocol/build/packages/libero/gleam.toml is missing)
• Chase `gleam build --target erlang`
• Chase `gleam build --target javascript`
• Chase `gleam test --target erlang`
• SCOREBOARD_BASE_URL=http://localhost:8099 node test/ws_result_smoke.mjs
• SCOREBOARD_BASE_URL=http://localhost:8100 node test/browser_smoke.mjs
