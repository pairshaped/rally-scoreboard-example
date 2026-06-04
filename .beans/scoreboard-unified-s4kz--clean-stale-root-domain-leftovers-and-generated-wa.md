---
# scoreboard-unified-s4kz
title: Clean stale root-domain leftovers and generated warnings
status: todo
type: task
priority: normal
tags:
    - rally
    - chase
created_at: 2026-06-04T03:38:31Z
updated_at: 2026-06-04T03:38:31Z
parent: scoreboard-unified-wm8p
blocked_by:
    - scoreboard-unified-qf1q
    - scoreboard-unified-4pk9
---

## What to build

Remove stale global-domain residue and warning noise left from the chase spike. The most visible examples are root API/domain shapes that no longer match page-local models and generated modules that emit known unused warnings.

This is not cosmetic. Warning churn and stale generated shapes make the framework feel less trustworthy and make it harder to see real regressions.

## Plan outline

- Remove stale fields such as root `GameDetail.scoring_summary` once no path uses them.
- Delete root API/domain constructors and helpers after page-local contracts replace them.
- Fix generated Libero dispatch warnings, including the unused `message` binding.
- Remove hand-edited generated artifacts that become obsolete once Rally generates the glue.
- Keep `gleam format` as the final authority on import ordering.
- Run the full chase validation suite.

## Acceptance criteria

- [ ] Stale root-domain fields are gone.
- [ ] Obsolete root API/domain modules are removed or reduced to only still-needed temporary bridge types.
- [ ] Generated-code warnings that are in scope are fixed.
- [ ] `gleam build --target javascript`, `gleam build --target erlang`, `gleam test`, and browser smoke pass.
- [ ] No generated/import-format churn remains beyond what `gleam format` produces.

## Blocked by

- Remaining public load migration.
- Admin load/save migration.
