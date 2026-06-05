# Separate Mutation Results From Broadcast Events

Mutations have two outputs with different audiences.

The correlated request result goes back to the connection that sent the command. It carries the success or error payload that the initiating page needs to finish its local workflow. That payload can be page-local and command-specific.

Broadcast events go to other subscribed connections. They carry the state event those other connections need to converge on the new server state. Broadcast event types that are consumed across pages live in `src/broadcasts.gleam`. The payload can differ from the correlated result payload.

Root broadcast modules define app-wide event payloads and message names. Page interest in those events is page-owned. Pages declare or expose the topics they subscribe to, and generated transport glue joins and leaves those topics as the active page changes. Root user-authored modules should not decide which page constructors receive a broadcast by matching generated page enums.

The origin connection is excluded from the broadcast caused by its own mutation. Other connections on the same page, including other browser tabs for the same user, still receive the broadcast when they are subscribed.

This keeps command replies separate from pubsub events. The initiating page updates from its ack payload. Other clients update from broadcasts. Rally owns request correlation and transport mechanics; application code owns the page-local command result shape, root broadcast event shape, sender-side broadcast meaning, and page-level subscription policy.
