---
# scoreboard-01nw
title: Investigate combining SPA navigation page-init and load frames
status: todo
type: task
priority: normal
tags:
    - protocol
    - websocket
created_at: 2026-05-30T19:28:36Z
updated_at: 2026-05-30T19:28:36Z
---

## Problem

SPA navigation in the generated/sibling app is small, but it is chatty. Navigating public `/standings` -> `/games` currently sends two upstream ETF frames and receives a nil ack before the actual data push.

Observed frame sequence:

1. `31B` up: page init for `Games`
2. `31B` up: `LoadGames`
3. `11B` down: nil page-init ack
4. `~2.5KB` down: `GamesLoaded` data push

This is already much smaller than the server-component app's rendered VDOM patches, but the sibling protocol may be able to remove at least one upstream frame and the nil ack.

## Captured ETF frames

First upstream frame, copied from DevTools as base64:

```text
g2gDbQAAAAVHYW1lc2EAaAJtAAAABG51bGx0AAAAAA==
```

Decoded:

```erlang
{<<"Games">>, 0, {<<"null">>, #{}}}
```

Meaning: `page_init Games`, request id `0`, params `"null"`, empty query.

Second upstream frame, copied from DevTools as base64:

```text
g2gDbQAAAAl0b19zZXJ2ZXJhAXcKbG9hZF9nYW1lcw==
```

Decoded:

```erlang
{<<"to_server">>, 1, load_games}
```

Meaning: root API command `LoadGames`, request id `1`.

Downstream ack frame, copied from DevTools as base64:

```text
AAAAAACDdwNuaWw=
```

Decoded frame layout:

```text
00                 response frame tag
00 00 00 00        request id 0
83 77 03 6e 69 6c  ETF atom nil
```

Meaning: empty page-init acknowledgement.

Downstream data frame, copied from DevTools as base64:

```text
AYNoAm0AAAAJdG9fY2xpZW50aAJ3DGdhbWVzX2xvYWRlZGwAAAAPaAd3E3B1YmxpY19nYW1lX3N1bW1hcnlhAWgEdwR0ZWFtbQAAAANUT1JtAAAADlRvcm9udG8gVG93ZXJzbQAAAA50b3JvbnRvLXRvd2Vyc2gEdwR0ZWFtbQAAAANNVExtAAAAEE1vbnRyZWFsIE1ldGVvcnNtAAAAEW1vbnRyw6lhbC1tZXRlb3JzYRFhDGgCdwRsaXZlbQAAAAM0dGhoB3cTcHVibGljX2dhbWVfc3VtbWFyeWECaAR3BHRlYW1tAAAAA1ZBTm0AAAASVmFuY291dmVyIFZveWFnZXJzbQAAABJ2YW5jb3V2ZXItdm95YWdlcnNoBHcEdGVhbW0AAAADTllDbQAAAA9OZXcgWW9yayBDb21ldHNtAAAAD25ldy15b3JrLWNvbWV0c2EGYQNoAncEbGl2ZW0AAAADNHRoaAd3E3B1YmxpY19nYW1lX3N1bW1hcnlhA2gEdwR0ZWFtbQAAAANCT1NtAAAAEEJvc3RvbiBCbGl6emFyZHNtAAAAEGJvc3Rvbi1ibGl6emFyZHNoBHcEdGVhbW0AAAADTEFLbQAAABNMb3MgQW5nZWxlcyBLbmlnaHRzbQAAABNsb3MtYW5nZWxlcy1rbmlnaHRzYQBhAGgCdwRsaXZlbQAAAAlTY2hlZHVsZWRoB3cTcHVibGljX2dhbWVfc3VtbWFyeWEEaAR3BHRlYW1tAAAAA1RPUm0AAAAOVG9yb250byBUb3dlcnNtAAAADnRvcm9udG8tdG93ZXJzaAR3BHRlYW1tAAAAA1ZBTm0AAAASVmFuY291dmVyIFZveWFnZXJzbQAAABJ2YW5jb3V2ZXItdm95YWdlcnNhBWEDdwVmaW5hbGgHdxNwdWJsaWNfZ2FtZV9zdW1tYXJ5YQVoBHcEdGVhbQAAAANUT1JtAAAADlRvcm9udG8gVG93ZXJzbQAAAA50b3JvbnRvLXRvd2Vyc2gEdwR0ZWFtbQAAAADTllDbQAAAA9OZXcgWW9yayBDb21ldHNtAAAAD25ldy15b3JrLWNvbWV0c2EAYQBoAncEbGl2ZW0AAAAJU2NoZWR1bGVkaAd3E3B1YmxpY19nYW1lX3N1bW1hcnlhBmgEdwR0ZWFtbQAAAANUT1JtAAAADlRvcm9udG8gVG93ZXJzbQAAAA50b3JvbnRvLXRvd2Vyc2gEdwR0ZWFtbQAAAANCT1NtAAAAEEJvc3RvbiBCbGl6emFyZHNtAAAAEGJvc3Rvbi1ibGl6emFyZHNhBmEEdwVmaW5hbGgHdxNwdWJsaWNfZ2FtZV9zdW1tYXJ5YQdoBHcEdGVhbW0AAAADVE9SbQAAAA5Ub3JvbnRvIFRvd2Vyc20AAAAOdG9yb250by10b3dlcnNoBHcEdGVhbW0AAAADTEFLbQAAABNMb3MgQW5nZWxlcyBLbmlnaHRzbQAAABNsb3MtYW5nZWxlcy1rbmlnaHRzYQBhAGgCdwRsaXZlbQAAAAlTY2hlZHVsZWRoB3cTcHVibGljX2dhbWVfc3VtbWFyeWEIaAR3BHRlYW1tAAAAA01UTG0AAAAQTW9udHJlYWwgTWV0ZW9yc20AAAARbW9udHLDqWFsLW1ldGVvcnNoBHcEdGVhbW0AAAADVkFObQAAABJWYW5jb3V2ZXIgVm95YWdlcnNtAAAAEnZhbmNvdXZlci12b3lhZ2Vyc2EAYQBoAncEbGl2ZW0AAAAJU2NoZWR1bGVkaAd3E3B1YmxpY19nYW1lX3N1bW1hcnlhCWgEdwR0ZWFtbQAAAANNVExtAAAAEE1vbnRyZWFsIE1ldGVvcnNtAAAAEW1vbnRyw6lhbC1tZXRlb3JzaAR3BHRlYW1tAAAAA05ZQ20AAAAPTmV3IFlvcmsgQ29tZXRzbQAAAA9uZXcteW9yay1jb21ldHNhAmEFdwVmaW5hbGgHdxNwdWJsaWNfZ2FtZV9zdW1tYXJ5YQpoBHcEdGVhbW0AAAADTVRMbQAAABBNb250cmVhbCBNZXRlb3JzbQAAABFtb250csOpYWwtbWV0ZW9yc2gEdwR0ZWFtbQAAAANCT1NtAAAAEEJvc3RvbiBCbGl6emFyZHNtAAAAEGJvc3Rvbi1ibGl6emFyZHNhAGEAaAJ3BGxpdmVtAAAACVNjaGVkdWxlZGgHdxNwdWJsaWNfZ2FtZV9zdW1tYXJ5YQtoBHcEdGVhbW0AAAADTVRMbQAAABBNb250cmVhbCBNZXRlb3JzbQAAABFtb250csOpYWwtbWV0ZW9yc2gEdwR0ZWFtbQAAAANMQUttAAAAE0xvcyBBbmdlbGVzIEtuaWdodHNtAAAAE2xvcy1hbmdlbGVzLWtuaWdodHNhA2EEdwVmaW5hbGgHdxNwdWJsaWNfZ2FtZV9zdW1tYXJ5YQxoBHcEdGVhbW0AAAADVkFObQAAABJWYW5jb3V2ZXIgVm95YWdlcnNtAAAAEnZhbmNvdXZlci12b3lhZ2Vyc2gEdwR0ZWFtbQAAAANCT1NtAAAAEEJvc3RvbiBCbGl6emFyZHNtAAAAEGJvc3Rvbi1ibGl6emFyZHNhAGEAaAJ3BGxpdmVtAAAACVNjaGVkdWxlZGgHdxNwdWJsaWNfZ2FtZV9zdW1tYXJ5YQ1oBHcEdGVhbW0AAAADVkFObQAAABJWYW5jb3V2ZXIgVm95YWdlcnNtAAAAEnZhbmNvdXZlci12b3lhZ2Vyc2gEdwR0ZWFtbQAAAANMQUttAAAAE0xvcyBBbmdlbGVzIEtuaWdodHNtAAAAE2xvcy1hbmdlbGVzLWtuaWdodHNhB2EGdwVmaW5hbGgHdxNwdWJsaWNfZ2FtZV9zdW1tYXJ5YQ5oBHcEdGVhbW0AAAADTllDbQAAAA9OZXcgWW9yayBDb21ldHNtAAAAD25ldy15b3JrLWNvbWV0c2gEdwR0ZWFtbQAAAANCT1NtAAAAEEJvc3RvbiBCbGl6emFyZHNtAAAAEGJvc3Rvbi1ibGl6emFyZHNhAGEAaAJ3BGxpdmVtAAAACVNjaGVkdWxlZGgHdxNwdWJsaWNfZ2FtZV9zdW1tYXJ5YQ9oBHcEdGVhbW0AAAADTllDbQAAAA9OZXcgWW9yayBDb21ldHNtAAAAD25ldy15b3JrLWNvbWV0c2gEdwR0ZWFtbQAAAANMQUttAAAAE0xvcyBBbmdlbGVzIEtuaWdodHNtAAAAE2xvcy1hbmdlbGVzLWtuaWdodHNhBWECdwVmaW5hbGo=
```

Decoded prefix:

```erlang
{<<"to_client">>, {games_loaded, [15 public_game_summary records...]}}
```

Meaning: actual Games data push.

## Candidate direction

Investigate combining page init and initial load command for SPA navigation, for example:

- allow `page_init` to carry an optional command list, or
- introduce one navigation frame that includes route module, params, query, and initial commands.

The target behavior for `/standings` -> `/games` would be closer to:

1. one upstream navigation/init frame
2. one downstream `GamesLoaded` push

Avoid losing authentication/request-context behavior. The page init currently establishes request context before `to_server` dispatch, so any combined frame needs to preserve that ordering on the server.

## Acceptance criteria

- Document the current protocol sequence and proposed replacement.
- If implementing, add or update tests covering SPA navigation page init plus route load.
- Verify no regression for authenticated admin navigation and command handling.
- Verify the browser message sequence no longer includes a separate nil page-init ack for the navigation case, unless there is a clear reason to keep it.
