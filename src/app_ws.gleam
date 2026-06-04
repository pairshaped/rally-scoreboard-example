@target(erlang)
import generated/libero/result as wire_result
@target(erlang)
import generated/libero/server as generated_server

@target(erlang)
import gleam/dynamic/decode
@target(erlang)
import gleam/erlang/atom
@target(erlang)
import gleam/erlang/process.{type Selector}
@target(erlang)
import gleam/list
@target(erlang)
import gleam/option.{type Option, Some}
@target(erlang)
import gleam/result

@target(erlang)
import mist.{type Next, type WebsocketConnection, type WebsocketMessage}
@target(erlang)
import sqlight

@target(erlang)
import api/to_client.{type ToClient}
@target(erlang)
import api/to_server.{type ToServer}
@target(erlang)
import app_api
@target(erlang)
import app_topics
@target(erlang)
import public/pages/games as public_games_page
@target(erlang)
import public/pages/games/wire as public_games_wire
@target(erlang)
import public/pages/standings as public_standings_page
@target(erlang)
import public/pages/standings/wire as public_standings_wire

// TYPES

@target(erlang)
pub type State {
  State(db: sqlight.Connection, admin_authorized: Bool)
}

// INIT

@target(erlang)
pub fn on_init(
  _conn: WebsocketConnection,
  db: sqlight.Connection,
  admin_authorized: Bool,
) -> #(State, Option(Selector(BitArray))) {
  app_topics.start()
  app_topics.join("app")
  let selector =
    process.new_selector()
    |> process.select_record(
      tag: atom.create("scoreboard_frame"),
      fields: 1,
      mapping: fn(msg) {
        msg
        |> decode.run(decode.at([1], decode.bit_array))
        |> result.unwrap(<<>>)
      },
    )
  #(State(db: db, admin_authorized:), Some(selector))
}

@target(erlang)
pub fn on_close(_state: State) -> Nil {
  Nil
}

// HANDLER

@target(erlang)
pub fn handler(
  state state: State,
  msg msg: WebsocketMessage(BitArray),
  conn conn: WebsocketConnection,
) -> Next(State, BitArray) {
  case msg {
    mist.Binary(data) -> {
      handle_client_frame(state: state, conn: conn, data: data)
      mist.continue(state)
    }
    mist.Custom(frame) -> {
      let _sent = mist.send_binary_frame(conn, frame)
      mist.continue(state)
    }
    mist.Text(_) -> mist.continue(state)
    mist.Closed -> mist.stop()
    mist.Shutdown -> mist.stop()
  }
}

// HELPERS

@target(erlang)
fn handle_client_frame(
  state state: State,
  conn conn: WebsocketConnection,
  data data: BitArray,
) -> Nil {
  case generated_server.decode_public_games_request(data) {
    Ok(generated_server.PublicGamesClientRequest(
      request_id: request_id,
      module: "public/pages/games",
      message: public_games_wire.PublicGamesLoad,
    )) -> handle_public_games_load(state: state, conn: conn, request_id:)
    _ ->
      case generated_server.decode_public_standings_request(data) {
        Ok(generated_server.PublicStandingsClientRequest(
          request_id: request_id,
          module: "public/pages/standings",
          message: public_standings_wire.PublicStandingsLoad,
        )) ->
          handle_public_standings_load(state: state, conn: conn, request_id:)
        _ -> handle_root_client_frame(state: state, conn: conn, data: data)
      }
  }
}

@target(erlang)
fn handle_public_games_load(
  state state: State,
  conn conn: WebsocketConnection,
  request_id request_id: Int,
) -> Nil {
  let result = case public_games_page.load(state.db) {
    Ok(games) ->
      Ok(
        public_games_wire.PublicGamesLoaded(list.map(
          games,
          public_games_page.to_wire_summary,
        )),
      )
    Error(public_games_page.LoadError(message: message)) ->
      Error([wire_result.ApiLoadError(message:)])
  }

  let _sent =
    mist.send_binary_frame(
      conn,
      generated_server.encode_public_games_load_result(
        request_id: request_id,
        result: result,
      ),
    )
  Nil
}

@target(erlang)
fn handle_public_standings_load(
  state state: State,
  conn conn: WebsocketConnection,
  request_id request_id: Int,
) -> Nil {
  let result = case public_standings_page.load(state.db) {
    Ok(games) ->
      Ok(
        public_standings_wire.PublicStandingsLoaded(list.map(
          games,
          public_standings_page.to_wire_summary,
        )),
      )
    Error(public_standings_page.LoadError(message: message)) ->
      Error([wire_result.ApiLoadError(message:)])
  }

  let _sent =
    mist.send_binary_frame(
      conn,
      generated_server.encode_public_standings_load_result(
        request_id: request_id,
        result: result,
      ),
    )
  Nil
}

@target(erlang)
fn handle_root_client_frame(
  state state: State,
  conn conn: WebsocketConnection,
  data data: BitArray,
) -> Nil {
  case generated_server.decode_request(data) {
    Ok(generated_server.ClientRequest(
      request_id: request_id,
      message: request_message,
      ..,
    )) -> {
      let reply =
        app_api.dispatch_reply(
          db: state.db,
          message: request_message,
          admin_authorized: state.admin_authorized,
        )
      let _sent =
        mist.send_binary_frame(conn, app_api.reply_result(reply, request_id:))
      case reply {
        app_api.LoadReply(..) -> Nil
        app_api.SaveReply(messages: messages, ..) ->
          list.each(messages, fn(message) {
            broadcast_if_live_update(request: request_message, reply: message)
          })
      }
    }
    Error(Nil) -> Nil
  }
}

@target(erlang)
fn broadcast_if_live_update(
  request request: ToServer,
  reply reply: ToClient,
) -> Nil {
  case should_broadcast_live_update(request: request, reply: reply) {
    True ->
      app_topics.broadcast("app", app_api.push(module: "app", message: reply))
    False -> Nil
  }
}

// nolint: unused_exports -- tests lock down the mutation-only broadcast policy.
@target(erlang)
pub fn should_broadcast_live_update(
  request request: ToServer,
  reply reply: ToClient,
) -> Bool {
  case request, reply {
    _, to_client.GameUpdated(_) -> True
    _, _ -> False
  }
}
