---
# scoreboard-2uax
title: Fix SSR RequestContext for unified page load
status: completed
type: bug
priority: high
created_at: 2026-05-28T14:35:25Z
updated_at: 2026-05-28T14:40:30Z
parent: scoreboard-v94b
---

## What to build

Fix the request context built by generated SSR handlers now that SSR and SPA load paths call the same server page load functions. SSR must pass the same request facts that a page load would expect during live navigation.

## Acceptance criteria

- [x] Public SSR RequestContext includes signed-in user_id when authentication_context has a user.
- [x] Admin SSR RequestContext includes signed-in user_id when authentication_context has a user.
- [x] Admin SSR passes the real query dictionary into RequestContext.
- [x] Route and query params remain strings; no generated coercion is added.
- [x] Existing SSR behavior tests and generated snapshots are updated.
- [x] Full test suite passes.

## Blocked by

None - can start immediately.

## Notes for Claude

This was a follow-up to the load/load_ssr consolidation. Do not reintroduce load_*_for_ssr functions. The desired convention has since been pinned down in ADR 0006: server page `init` is the SSR boot hook, shared `init_requests` declares first-render requests, and `ToServer.Load*` constructors map to explicit snake_case handlers such as `load_games`.

## Summary of Changes

Verified both generated SSR handlers derive RequestContext.user_id from authentication_context, admin SSR passes query through, route/query params remain strings, and Claude reported all tests passing: 82 server unit tests, 4 client unit tests, and 24 smoke checks.
