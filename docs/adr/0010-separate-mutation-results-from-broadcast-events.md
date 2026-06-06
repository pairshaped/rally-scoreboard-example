# Separate Mutation Results From Broadcast Events

Mutations have two outputs with different audiences.

The correlated request result goes back to the connection that sent the command. It carries the success or error payload that the initiating page needs to finish its local workflow. That payload can be page-local and command-specific.

Broadcast events go to other subscribed connections. They carry the state event those other connections need to converge on the new server state. Broadcast event types that are consumed across pages live in `src/broadcasts.gleam`. The payload can differ from the correlated result payload.

Root broadcast modules define app-wide event payloads and message names. Page interest in those events is page-owned. Pages declare or expose the topics they subscribe to, and generated transport glue joins and leaves those topics as the active page changes. Root user-authored modules should not decide which page constructors receive a broadcast by matching generated page enums.

Pages expose typed topic values, such as `broadcasts.Topic`, not raw wire strings. Generated Rally glue maps those typed values through the app-owned topic-name function before synchronizing transport state. The wire topic key is a stable domain key such as `games` or `game:3`, not a rendered Gleam constructor such as `GameTopic(3)`. Constructor names and field shapes may change without changing the pubsub topic identity.

Topic synchronization is a small text websocket control protocol. The client sends the complete current topic set as `sub:topic` or `sub:topic,other-topic`; it sends `unsub` when the complete current set is empty. These frames are transport control frames, not page-local ETF payloads. Load/save requests, results, and push events remain typed ETF frames. Keeping topic sync as text makes the control path easy to inspect, independent from page-local codecs, and boring to parse.

`sub:` frames are full replacement, not incremental subscribe operations. If a connection is currently subscribed to `games` and sends `sub:game:3`, the server leaves `games`, joins `game:3`, and stores `game:3` as that connection's current topic set. `unsub` is the empty full-state frame. The client does not need to calculate a topic diff; the server owns the diff for each connection.

Broadcast filtering happens on the server. Each websocket connection keeps its own current topic set in server-side connection state. Generated websocket glue joins and leaves server-side topic groups as sync frames arrive, and it leaves all joined topics when the connection closes. The browser should not receive every broadcast and filter locally.

The server should not infer topic changes from page load requests. A load request is not always a navigation, not every navigation has a load request, and topics may change after local updates or push events. Generated browser glue syncs topics after page state changes because the browser owns the active page model in the TEA app. When a page can derive its next topics from route params before data loads, Rally may avoid temporary empty topic states, but the transport contract remains explicit full-state sync.

For dynamic pages, generated page state retains route params and generated Rally browser glue passes those params to the page's topic hook. This lets route-backed pages declare interest before load data arrives. For example, a game detail page can subscribe to `game:1` from `/games/1` immediately, instead of first exposing an empty topic set while `game` is still loading.

The origin connection is excluded from the broadcast caused by its own mutation. Other connections on the same page, including other browser tabs for the same user, still receive the broadcast when they are subscribed.

This keeps command replies separate from pubsub events. The initiating page updates from its ack payload. Other clients update from broadcasts. Rally owns request correlation and transport mechanics; application code owns the page-local command result shape, root broadcast event shape, sender-side broadcast meaning, and page-level subscription policy.
