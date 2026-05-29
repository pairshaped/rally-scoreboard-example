---
# scoreboard-ibzc
title: Replace live broadcasts with game event payloads
status: completed
type: task
priority: normal
created_at: 2026-05-29T00:15:37Z
updated_at: 2026-05-29T02:07:26Z
parent: scoreboard-v94b
---

Replace live ToClient broadcasts with public-safe game event payloads. Introduce a shared GameSnapshot-style payload, emit GameCreated(game:) and GameUpdated(game:) on the live broadcast lane, remove GameScoreUpdated and StandingsUpdated broadcasts, and update client page mini-updates/tests/smokes accordingly. Admin direct responses may keep admin-only payloads where appropriate.
