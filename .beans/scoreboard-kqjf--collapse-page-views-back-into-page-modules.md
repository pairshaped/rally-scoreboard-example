---
# scoreboard-kqjf
title: Collapse page views back into page modules
status: todo
type: task
priority: high
tags:
    - pages
    - cleanup
created_at: 2026-06-02T10:03:55Z
updated_at: 2026-06-02T10:03:55Z
parent: scoreboard-d0g1
blocked_by:
    - scoreboard-eulm
---

## Problem

The unified app has both pages and views. That split is adding ceremony without a clear boundary. The SC app keeps the meaningful page behavior close to the page module, especially under server/src/server/public/pages and server/src/server/admin/pages.

In unified, view modules also carry init_requests(), which looks like a fossil from an older route boot design. Views should render. They should not declare page data loading.

## Direction

Collapse src/public/views/* and src/admin/views/* into their corresponding src/public/pages/* and src/admin/pages/* modules unless a helper is reused enough to earn a separate components module. Treat page modules as the authored unit for model, initial model, loading intent, update, ToClient handling, and view.

Do this route by route so behavior remains easy to verify.

## Acceptance criteria

- Page modules expose their own view functions directly.
- init_requests() is removed from view modules and either deleted or represented in page/init logic.
- src/public/views and src/admin/views are deleted or reduced to genuinely reusable view helpers.
- No user-visible HTML or behavior changes except incidental markup simplification.
- Gleam format, check, tests, JS/Erlang builds, glinter, and browser smoke pass.
