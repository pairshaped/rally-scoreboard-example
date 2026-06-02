---
# scoreboard-1yxu
title: Remove unused power rankings response from standings load
status: completed
type: task
priority: normal
tags:
    - protocol
    - websocket
    - cleanup
created_at: 2026-06-02T10:40:13Z
updated_at: 2026-06-02T10:52:00Z
---

## Problem

Navigating from public Games to Standings sends three websocket frames:

1. ToServer LoadStandings from the browser.
2. ToClient StandingsLoaded with standings rows.
3. ToClient PowerRankingsLoaded with power-ranking rows.

Navigating back from Standings to Games only sends two frames: request plus response. The extra standings response appears to be because server/api.gleam returns both StandingsLoaded and PowerRankingsLoaded for LoadStandings, while the public standings page only consumes StandingsLoaded.

Observed payloads:

- request: g2gDbQAAABBwdWJsaWMvc3RhbmRpbmdzYQF3DmxvYWRfc3RhbmRpbmdz
- standings response: AAAAAAGDaAJ3EHN0YW5kaW5nc19sb2FkZWRsAAAABmgIdwxzdGFuZGluZ19yb3dtAAAAA1RPUm0AAAAOVG9yb250byBUb3dlcnNtAAAADnRvcm9udG8tdG93ZXJzYQNhAWETYQ9oCHcMc3RhbmRpbmdfcm93bQAAAANOWUNtAAAAD05ldyBZb3JrIENvbWV0c20AAAAPbmV3LXlvcmstY29tZXRzYQJhAWEOYQloCHcMc3RhbmRpbmdfcm93bQAAAANMQUttAAAAE0xvcyBBbmdlbGVzIEtuaWdodHNtAAAAE2xvcy1hbmdlbGVzLWtuaWdodHNhAWECYQxhD2gIdwxzdGFuZGluZ19yb3dtAAAAA1ZBTm0AAAASVmFuY291dmVyIFZveWFnZXJzbQAAABJ2YW5jb3V2ZXItdm95YWdlcnNhAWEBYQthDGgIdwxzdGFuZGluZ19yb3dtAAAAA01UTG0AAAAQTW9udHJlYWwgTWV0ZW9yc20AAAARbW9udHLDqWFsLW1ldGVvcnNhAWECYQphDWgIdwxzdGFuZGluZ19yb3dtAAAAA0JPU20AAAAQQm9zdG9uIEJsaXp6YXJkc20AAAAQYm9zdG9uLWJsaXp6YXJkc2EAYQFhBGEGag==
- power rankings response: AAAAAAGDaAJ3FXBvd2VyX3JhbmtpbmdzX2xvYWRlZGwAAAAGaAh3EXBvd2VyX3Jhbmtpbmdfcm93bQAAAANUT1JtAAAADlRvcm9udG8gVG93ZXJzbQAAAA50b3JvbnRvLXRvd2Vyc2EDYQFhE2EPaAh3EXBvd2VyX3Jhbmtpbmdfcm93bQAAAANOWUNtAAAAD05ldyBZb3JrIENvbWV0c20AAAAPbmV3LXlvcmstY29tZXRzYQJhAWEOYQloCHcRcG93ZXJfcmFua2luZ19yb3dtAAAAA0xBS20AAAATTG9zIEFuZ2VsZXMgS25pZ2h0c20AAAATbG9zLWFuZ2VsZXMta25pZ2h0c2EBYQJhDGEPaAh3EXBvd2VyX3Jhbmtpbmdfcm93bQAAAANWQU5tAAAAElZhbmNvdXZlciBWb3lhZ2Vyc20AAAASdmFuY291dmVyLXZveWFnZXJzYQFhAWELYQxoCHcRcG93ZXJfcmFua2luZ19yb3dtAAAAA01UTG0AAAAQTW9udHJlYWwgTWV0ZW9yc20AAAARbW9udHLDqWFsLW1ldGVvcnNhAWECYQphDWgIdxFwb3dlcl9yYW5raW5nX3Jvd20AAAADQk9TbQAAABBCb3N0b24gQmxpenphcmRzbQAAABBib3N0b24tYmxpenphcmRzYQBhAWEEYQZq

## Direction

Remove the unused PowerRankingsLoaded response from LoadStandings unless a current page or test actually consumes it. Keep PowerRankingsLoaded in the API only if it is still needed as a Libero same-shape codec fixture; do not emit it on normal standings navigation just to exercise the generator.

## Acceptance criteria

- Public Standings navigation sends only LoadStandings plus StandingsLoaded.
- SSR standings hydration emits only the needed standings payload.
- Existing Libero same-shape constructor coverage remains covered elsewhere if PowerRankingsLoaded stays in the API graph.
- Gleam tests and browser smoke pass.

## Resolution

LoadStandings now returns only StandingsLoaded. PowerRankingsLoaded remains in the API graph as a generator fixture but is not emitted by normal standings navigation.

The browser smoke test now runs on port 8081 by default, while local user sessions keep port 8080. The app reads PORT from the environment or .env, defaulting to 8080.
