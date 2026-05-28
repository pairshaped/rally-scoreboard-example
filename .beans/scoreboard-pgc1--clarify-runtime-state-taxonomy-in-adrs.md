---
# scoreboard-pgc1
title: Clarify runtime state taxonomy in ADRs
status: completed
type: task
priority: high
created_at: 2026-05-28T16:42:09Z
updated_at: 2026-05-28T16:47:11Z
parent: scoreboard-v94b
---

## What to build

Clarify the ADR vocabulary for client-visible and server-visible state so ClientSharedState is not treated as an accidental synonym for older client context wording.

## Acceptance criteria

- [x] ADRs define the project taxonomy for AuthenticationContext, RequestContext, ServerContext, ClientSharedState, SSR page data payload, page Model, backend Model, ToServer, and ToClient.
- [x] ADRs stop using client context vocabulary for the intended design.
- [x] The taxonomy distinguishes ClientSharedState from SSR ToClient hydration/page data.
- [x] beans check passes.

## Blocked by

None - can start immediately.

## Summary of Changes

Updated ADR 0006 with an explicit runtime taxonomy for AuthenticationContext, RequestContext, ServerContext, ClientSharedState, SSR ToClient page data, page Model, backend.Model, ToServer, and ToClient. Updated ADR 0007 and ADR 0008 to use ClientSharedState instead of client context. The docs now explicitly separate Mount-level ClientSharedState from SSR ToClient page-data hydration and reserve separate runtime storage names for the two boot payloads.
