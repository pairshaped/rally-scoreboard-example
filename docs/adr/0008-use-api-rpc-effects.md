# Use API RPC Effects

Page code sends page-local `ServerMsg` values through a Rally API/RPC effect. The effect returns a Lustre `Effect(Msg)`.

```gleam
server.send(ServerSave(form), on_result: Saved)
```

`ServerMsg` is the page-local server request type. `Msg` is the browser update message type. Rally should keep work returned from `init` and `update` as Lustre `Effect(Msg)`.

The result payload stays a normal `Result(success, error)`. A save with no success payload uses `Result(Nil, SaveError)`. A create flow can use `Result(Item, SaveError)`.

`on_result` receives that `Result` directly and returns the page's local `Msg`. Rally should not replace `Result` with a custom outcome type and should not force page code to inspect request ids.

The page chooses the completion message. The common form path should require no extra ceremony:

```gleam
pub type Msg {
  SaveClicked
  Saved(Result(Item, SaveError))
}

server.send(ServerSave(form), on_result: Saved)
```

Pages carry local context only when the completion handler needs it:

```gleam
pub type Msg {
  AdjustHome(game_id: Int, delta: Int)
  ScoreSaved(game_id: Int, Result(Nil, SaveError))
}

server.send(
  ServerUpdateScore(game_id:, home_score:, away_score:),
  on_result: fn(result) { ScoreSaved(game_id, result) },
)
```

Rally owns request id generation, pending callback registration, wire encoding, result decoding, and dispatching the selected local `Msg`. Request ids are transport bookkeeping. Page code should not need to inspect request ids for normal form saves or score updates.

Server-originated state events are separate from request results. Request results manage lifecycle, pending state, errors, and the initiating page's command-specific success payload. Mutation broadcasts carry state events for other subscribed connections. The connection that initiated a mutation should not receive its own broadcast for that mutation.

Generated load/save transport helpers are internal Rally glue. Authored page code uses `server.send(ServerMsg, on_result: ...)` for page-local server commands, while generated Rally browser glue owns standard page data loading.
