@target(erlang)
import admin/pages/games as admin_games_page
@target(erlang)
import app_api
@target(erlang)
import broadcasts
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
/// server_ws handlers use it to reach the database and auth flag.
pub type State {
  State(db: sqlight.Connection, admin_authorized: Bool, topics: List(String))
}

// INIT

@target(erlang)
/// Mist websocket init callback.
/// scoreboard_unified passes this to mist.websocket so each connection can keep
/// its page topics, database, and authorization context.
pub fn on_init(
  _conn: WebsocketConnection,
  db: sqlight.Connection,
  admin_authorized: Bool,
) -> #(State, Option(Selector(BitArray))) {
  topics.start()
  #(State(db: db, admin_authorized:, topics: []), Some(topics.frame_selector()))
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
    admin_games_load: load_admin_games,
    admin_games_save: save_admin_games,
    after_admin_games_save: after_admin_games_save,
  )
}

@target(erlang)
fn load_admin_games(
  state: State,
) -> Result(admin_games_page.LoadResult, List(server_ws.LoadError)) {
  case state.admin_authorized {
    False -> Error([server_ws.LoadError(message: "Unauthorized.")])
    True -> admin_games_page.load_wire(state.db) |> map_load_wire_result
  }
}

@target(erlang)
fn save_admin_games(
  state: State,
  message: admin_games_page.ServerMsg,
) -> Result(admin_games_page.GameUpdate, List(server_ws.SaveError)) {
  case state.admin_authorized {
    False -> Error([server_ws.SaveError(field: None, message: "Unauthorized.")])
    True ->
      case admin_games_page.handle(state.db, message) {
        Ok(game) -> Ok(game)
        Error(admin_games_page.SaveError(message: message)) ->
          Error([server_ws.SaveError(field: None, message:)])
      }
  }
}

@target(erlang)
fn after_admin_games_save(
  state: State,
  message: admin_games_page.ServerMsg,
  _game: admin_games_page.GameUpdate,
) -> Nil {
  broadcast_admin_game_update(state: state, message: message)
}

@target(erlang)
fn broadcast_admin_game_update(
  state state: State,
  message message: admin_games_page.ServerMsg,
) -> Nil {
  case admin_games_request_game_id(message) {
    Ok(game_id) ->
      case app_api.game_updated_broadcast(state.db, game_id) {
        Ok(broadcasts.TargetedEvent(topics: target_topics, event: event)) ->
          target_topics
          |> list.each(fn(topic) {
            topics.broadcast_except_self(
              topic,
              server_ws.push_frame(module: topic, message: event),
            )
          })
        Error(Nil) -> Nil
      }
    Error(Nil) -> Nil
  }
}

@target(erlang)
fn admin_games_request_game_id(
  message: admin_games_page.ServerMsg,
) -> Result(Int, Nil) {
  case message {
    admin_games_page.AdminGamesUpdateScore(game_id, ..) -> Ok(game_id)
    admin_games_page.AdminGamesMarkFinal(game_id) -> Ok(game_id)
    admin_games_page.AdminGamesLoad -> Error(Nil)
  }
}

@target(erlang)
fn map_load_wire_result(
  result: Result(a, List(String)),
) -> Result(a, List(server_ws.LoadError)) {
  case result {
    Ok(value) -> Ok(value)
    Error(errors) ->
      Error(list.map(errors, fn(message) { server_ws.LoadError(message:) }))
  }
}
