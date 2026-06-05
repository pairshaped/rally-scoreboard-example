@target(erlang)
import app_auth
@target(erlang)
import generated/rally/server_ws
@target(erlang)
import gleam/erlang/process.{type Selector}
@target(erlang)
import gleam/list
@target(erlang)
import gleam/option.{type Option, None, Some}
@target(erlang)
import mist.{type Next, type WebsocketConnection, type WebsocketMessage}
@target(erlang)
import rally/runtime/topics
@target(erlang)
import sqlight

@target(javascript)
/// JavaScript-side compile anchor for the websocket module.
/// Browser builds can import this module without pulling in Erlang-only code.
pub fn ensure() -> Nil {
  Nil
}

// TYPES

@target(erlang)
/// Per-connection websocket state.
/// Mist threads this through on_init, handler, and on_close while generated Rally
/// server_ws handlers use it to reach the database and auth context.
pub type State {
  State(
    db: sqlight.Connection,
    admin_user: Option(app_auth.AuthenticatedUser),
    topics: List(String),
  )
}

// INIT

@target(erlang)
/// Mist websocket init callback.
/// scoreboard_unified passes this to mist.websocket so each connection can keep
/// its page topics, database, and authorization context.
pub fn on_init(
  _conn: WebsocketConnection,
  db: sqlight.Connection,
  admin_user: Option(app_auth.AuthenticatedUser),
) -> #(State, Option(Selector(BitArray))) {
  topics.start()
  #(State(db: db, admin_user:, topics: []), Some(topics.frame_selector()))
}

@target(erlang)
/// Mist websocket close callback.
/// scoreboard_unified passes this to mist.websocket so a closing connection can
/// leave any page topics it joined.
pub fn on_close(state: State) -> Nil {
  state.topics
  |> list.each(topics.leave)
}

// HANDLER

@target(erlang)
/// Mist websocket message callback.
/// scoreboard_unified passes this to mist.websocket; it forwards client frames to
/// generated Rally server_ws code and relays topic broadcasts back to the client.
pub fn handler(
  state state: State,
  msg msg: WebsocketMessage(BitArray),
  conn conn: WebsocketConnection,
) -> Next(State, BitArray) {
  case msg {
    mist.Binary(data) -> {
      server_ws.handle_client_frame(
        state: state,
        conn: conn,
        data: data,
        handlers: handlers(),
      )
      mist.continue(state)
    }
    mist.Custom(frame) -> {
      let _sent = mist.send_binary_frame(conn, frame)
      mist.continue(state)
    }
    mist.Text(frame) -> {
      case server_ws.sync_topic_frame(state.topics, frame) {
        Ok(next_topics) -> mist.continue(State(..state, topics: next_topics))
        Error(Nil) -> mist.continue(state)
      }
    }
    mist.Closed -> mist.stop()
    mist.Shutdown -> mist.stop()
  }
}

// HELPERS

@target(erlang)
fn handlers() -> server_ws.Handlers(State) {
  server_ws.Handlers(
    load_context: fn(state: State) { state.db },
    admin_authorized: fn(state: State) {
      case state.admin_user {
        Some(_) -> True
        None -> False
      }
    },
  )
}
