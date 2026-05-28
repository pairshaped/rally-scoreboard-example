---
# scoreboard-2uax
title: Fix SSR RequestContext for unified page load
status: todo
type: bug
priority: high
created_at: 2026-05-28T14:35:25Z
updated_at: 2026-05-28T14:35:25Z
parent: scoreboard-v94b
---

## What to build

Fix the request context built by generated SSR handlers now that SSR and SPA load paths call the same server page load functions. SSR must pass the same request facts that a page load would expect during live navigation.

## Acceptance criteria

- [ ] Public SSR RequestContext includes signed-in user_id when authentication_context has a user.
- [ ] Admin SSR RequestContext includes signed-in user_id when authentication_context has a user.
- [ ] Admin SSR passes the real query dictionary into RequestContext.
- [ ] Route and query params remain strings; no generated coercion is added.
- [ ] Existing SSR behavior tests and generated snapshots are updated.
- [ ] Full test suite passes.

## Blocked by

None - can start immediately.

## Notes for Claude

This is a follow-up to the load/load_ssr consolidation. Do not reintroduce load_*_for_ssr functions. The desired server page shape is still one load(request_context, server_context) -> ToClient per loadable page.
