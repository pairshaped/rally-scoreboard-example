@target(erlang)
import api/to_client.{type ToClient}
@target(erlang)
import api/to_server.{type ToServer}
@target(erlang)
import app_api
@target(erlang)
import app_topics
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
pub type State {
  State(db: sqlight.Connection, admin_authorized: Bool)
}

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

@target(erlang)
fn handle_client_frame(
  state state: State,
  conn conn: WebsocketConnection,
  data data: BitArray,
) -> Nil {
  case generated_server.decode_request(data) {
    Ok(generated_server.ClientRequest(message: request_message, ..)) -> {
      let reply =
        app_api.dispatch_reply(
          db: state.db,
          message: request_message,
          admin_authorized: state.admin_authorized,
        )
      let _sent = mist.send_binary_frame(conn, app_api.reply_result(reply))
      case reply {
        app_api.LoadReply(messages: messages, ..) ->
          list.each(messages, fn(message) {
            let response = generated_server.encode_response(message)
            let _sent = mist.send_binary_frame(conn, response)
            Nil
          })
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
